import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';

/// Локальный ключ раздела «Люди».
/// Его нет в синхронизации Firestore и в файле резервной копии заведения:
/// облако для профилей подключается отдельно и не должно затирать заявки,
/// смены, склад и инвентаризацию.
const peoplePrefsKey = 'people_local_v1';

class PeopleRepository extends StateNotifier<PeopleSnapshot> {
  PeopleRepository(this._prefs) : super(PeopleSnapshot.empty) {
    _load();
  }

  final SharedPreferences _prefs;
  int _seq = 0;
  bool _canPersist = true;

  void _load() {
    final raw = _prefs.getString(peoplePrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final parsed = PeopleSnapshot.tryParse(jsonDecode(raw));
      if (parsed == null) {
        // Чужая или будущая версия остаётся на диске как была.
        _canPersist = false;
        return;
      }
      state = parsed;
    } catch (_) {
      _canPersist = false;
    }
  }

  void _save() {
    if (!_canPersist) return;
    _prefs.setString(peoplePrefsKey, jsonEncode(state.toJson()));
  }

  String _localId(String prefix) {
    _seq += 1;
    return '$prefix-$_seq-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Будущая версия файла остаётся как есть: экран её не переписывает.
  String? _blocked() {
    if (_canPersist) return null;
    return 'Запись «Людей» на телефоне новее этого приложения. Экран её не меняет.';
  }

  /// Первый профиль на этом телефоне. Повторный вызов ID не меняет.
  String? createProfile(String name, {Random? random, DateTime? now}) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    if (state.me != null) return null;
    final error = validatePersonName(name, emptyText: 'Напишите имя.');
    if (error != null) return error;
    final profile = PersonProfile(
      id: createPersonId(random ?? Random.secure()),
      name: tidyText(name),
      photoPath: null,
      skills: const [],
      awards: const [],
      workplaces: const [],
      album: const [],
      createdAt: now ?? DateTime.now(),
    );
    state = state.copyWith(me: profile);
    _save();
    return null;
  }

  String? rename(String name) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    final error = validatePersonName(name, emptyText: 'Напишите имя.');
    if (error != null) return error;
    state = state.copyWith(me: me.copyWith(name: tidyText(name)));
    _save();
    return null;
  }

  void setPhotoPath(String? path) {
    if (_blocked() != null) return;
    final me = state.me;
    if (me == null) return;
    final tidy = path?.trim() ?? '';
    state = state.copyWith(
      me: tidy.isEmpty ? me.copyWith(clearPhoto: true) : me.copyWith(photoPath: tidy),
    );
    _save();
  }

  String? addSkill(String skill) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    final error = validateSkill(skill, me.skills);
    if (error != null) return error;
    state = state.copyWith(me: me.copyWith(skills: [...me.skills, tidyText(skill)]));
    _save();
    return null;
  }

  void removeSkill(String skill) {
    if (_blocked() != null) return;
    final me = state.me;
    if (me == null) return;
    final key = skillKey(skill);
    state = state.copyWith(
      me: me.copyWith(skills: me.skills.where((item) => skillKey(item) != key).toList()),
    );
    _save();
  }

  String? addAward(String title, String note) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    final error = validateAwardTitle(title);
    if (error != null) return error;
    final award = Award(id: _localId('award'), title: tidyText(title), note: tidyText(note));
    state = state.copyWith(me: me.copyWith(awards: [...me.awards, award]));
    _save();
    return null;
  }

  void removeAward(String id) {
    if (_blocked() != null) return;
    final me = state.me;
    if (me == null) return;
    state = state.copyWith(
      me: me.copyWith(awards: me.awards.where((award) => award.id != id).toList()),
    );
    _save();
  }

  String? addWorkplace({
    required String venueName,
    required HospitalityRole role,
    required DateTime startedAt,
    required DateTime? endedAt,
  }) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    final error = validateWorkplace(
      venueName: venueName,
      startedAt: startedAt,
      endedAt: endedAt,
    );
    if (error != null) return error;
    final place = WorkPlace(
      id: _localId('work'),
      venueName: tidyText(venueName),
      role: role,
      startedAt: dateOnly(startedAt),
      endedAt: endedAt == null ? null : dateOnly(endedAt),
      confirmed: false,
      confirmedByOwnerId: null,
    );
    state = state.copyWith(me: me.copyWith(workplaces: [...me.workplaces, place]));
    _save();
    return null;
  }

  /// Если изменились название, должность или даты, подтверждение снимается.
  /// true — подтверждение было и слетело.
  bool updateWorkplace({
    required String id,
    required String venueName,
    required HospitalityRole role,
    required DateTime startedAt,
    required DateTime? endedAt,
  }) {
    if (_blocked() != null) return false;
    final me = state.me;
    if (me == null) return false;
    final error = validateWorkplace(
      venueName: venueName,
      startedAt: startedAt,
      endedAt: endedAt,
    );
    if (error != null) return false;
    var cleared = false;
    final next = me.workplaces.map((place) {
      if (place.id != id) return place;
      final same = sameWorkplaceClaim(
        place,
        venueName: venueName,
        role: role,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      cleared = place.confirmed && !same;
      return place.copyWith(
        venueName: tidyText(venueName),
        role: role,
        startedAt: dateOnly(startedAt),
        endedAt: endedAt == null ? null : dateOnly(endedAt),
        clearEndedAt: endedAt == null,
        confirmed: same && place.confirmed,
        clearConfirmedBy: !same,
      );
    }).toList();
    state = state.copyWith(me: me.copyWith(workplaces: next));
    _save();
    return cleared;
  }

  String? workplaceValidationError({
    required String venueName,
    required DateTime startedAt,
    required DateTime? endedAt,
  }) {
    return validateWorkplace(
      venueName: venueName,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  void removeWorkplace(String id) {
    if (_blocked() != null) return;
    final me = state.me;
    if (me == null) return;
    state = state.copyWith(
      me: me.copyWith(
        workplaces: me.workplaces.where((place) => place.id != id).toList(),
      ),
    );
    _save();
  }

  /// Подтверждает место в личном профиле на этом телефоне.
  /// Допуск в заведение при этом не создаётся.
  String? confirmWorkplace(String workplaceId) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    final index = me.workplaces.indexWhere((place) => place.id == workplaceId);
    if (index < 0) return 'Место не найдено.';
    final place = me.workplaces[index];
    if (place.confirmed) return null;
    if (!canConfirmWorkplace(me: me, place: place, ownedVenues: state.ownedVenues)) {
      return 'Это место подтверждает владелец заведения с таким названием.';
    }
    final next = [...me.workplaces];
    next[index] = place.copyWith(confirmed: true, confirmedByOwnerId: me.id);
    state = state.copyWith(me: me.copyWith(workplaces: next));
    _save();
    return null;
  }

  /// Отказывает видео больше лимита и ничего не записывает.
  String? addAlbumItem({
    required AlbumKind kind,
    required String localPath,
    required int sizeBytes,
    DateTime? addedAt,
  }) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    if (localPath.trim().isEmpty) return 'Файл не выбран.';
    if (kind == AlbumKind.video) {
      final decision = decideVideoUpload(sizeBytes);
      if (!decision.allowed) return decision.message;
    }
    final item = AlbumItem(
      id: _localId('album'),
      kind: kind,
      localPath: localPath.trim(),
      sizeBytes: sizeBytes,
      addedAt: addedAt ?? DateTime.now(),
    );
    state = state.copyWith(me: me.copyWith(album: [...me.album, item]));
    _save();
    return null;
  }

  void removeAlbumItem(String id) {
    if (_blocked() != null) return;
    final me = state.me;
    if (me == null) return;
    state = state.copyWith(
      me: me.copyWith(album: me.album.where((item) => item.id != id).toList()),
    );
    _save();
  }

  String? addOwnedVenue(String name, {DateTime? now}) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final me = state.me;
    if (me == null) return 'Сначала создайте личный профиль.';
    final error = validateOwnedVenueName(name, state.ownedVenues);
    if (error != null) return error;
    final venue = OwnedVenue(
      id: _localId('venue'),
      name: tidyText(name),
      ownerProfileId: me.id,
      createdAt: now ?? DateTime.now(),
    );
    state = state.copyWith(ownedVenues: [...state.ownedVenues, venue]);
    _save();
    return null;
  }

  void removeOwnedVenue(String venueId) {
    if (_blocked() != null) return;
    state = state.copyWith(
      ownedVenues: state.ownedVenues.where((venue) => venue.id != venueId).toList(),
      accesses: state.accesses.where((access) => access.venueId != venueId).toList(),
    );
    _save();
  }

  String? createAccess({
    required String venueId,
    required String personName,
    required HospitalityRole position,
    required List<VenueSection> permissions,
    DateTime? now,
  }) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final venue = _venue(venueId);
    final error = validateAccessDraft(
      owner: state.me,
      venue: venue,
      personName: personName,
      permissions: permissions,
    );
    if (error != null) return accessErrorText(error);
    final access = VenueAccess(
      id: _localId('access'),
      venueId: venueId,
      personName: tidyText(personName),
      position: position,
      permissions: List<VenueSection>.from(permissions),
      createdByOwnerId: state.me!.id,
      createdAt: now ?? DateTime.now(),
    );
    state = state.copyWith(accesses: [...state.accesses, access]);
    _save();
    return null;
  }

  String? updateAccess({
    required String accessId,
    required String personName,
    required HospitalityRole position,
    required List<VenueSection> permissions,
  }) {
    final blocked = _blocked();
    if (blocked != null) return blocked;
    final current = state.accesses.where((access) => access.id == accessId);
    if (current.isEmpty) return 'Допуск не найден.';
    final access = current.first;
    final venue = _venue(access.venueId);
    final error = validateAccessDraft(
      owner: state.me,
      venue: venue,
      personName: personName,
      permissions: permissions,
    );
    if (error != null) return accessErrorText(error);
    final next = state.accesses
        .map(
          (item) => item.id == accessId
              ? item.copyWith(
                  personName: tidyText(personName),
                  position: position,
                  permissions: List<VenueSection>.from(permissions),
                )
              : item,
        )
        .toList();
    state = state.copyWith(accesses: next);
    _save();
    return null;
  }

  void removeAccess(String accessId) {
    if (_blocked() != null) return;
    state = state.copyWith(
      accesses: state.accesses.where((access) => access.id != accessId).toList(),
    );
    _save();
  }

  OwnedVenue? _venue(String id) {
    final found = state.ownedVenues.where((venue) => venue.id == id);
    return found.isEmpty ? null : found.first;
  }
}

final peopleRepositoryProvider =
    StateNotifierProvider<PeopleRepository, PeopleSnapshot>((ref) {
  return PeopleRepository(ref.read(sharedPreferencesProvider));
});
