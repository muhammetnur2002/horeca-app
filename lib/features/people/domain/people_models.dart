import 'dart:math';

/// Должность на конкретном месте. Тот же справочник, что и специальности
/// личного профиля: профиль собирает их из своих мест работы.
/// Допуск в заведение этим справочником пользуется, но сам профиль не создаёт.
enum HospitalityRole {
  waiter,
  bartender,
  barista,
  cook,
  administrator,
  manager,
}

const hospitalityRoleLabels = <HospitalityRole, String>{
  HospitalityRole.waiter: 'официант',
  HospitalityRole.bartender: 'бармен',
  HospitalityRole.barista: 'бариста',
  HospitalityRole.cook: 'повар',
  HospitalityRole.administrator: 'администратор',
  HospitalityRole.manager: 'менеджер',
};

String roleLabel(HospitalityRole role) => hospitalityRoleLabels[role]!;

HospitalityRole? roleFromName(String? name) {
  for (final role in HospitalityRole.values) {
    if (role.name == name) return role;
  }
  return null;
}

/// Разделы, которые владелец может открыть человеку в своём заведении.
/// Это подпись допуска, а не роль PIN администратора или сотрудника.
enum VenueSection {
  requests,
  inventory,
  shift,
  warehouse,
  history,
}

const venueSectionLabels = <VenueSection, String>{
  VenueSection.requests: 'Заявки',
  VenueSection.inventory: 'Инвентаризация',
  VenueSection.shift: 'Смена',
  VenueSection.warehouse: 'Склад',
  VenueSection.history: 'История',
};

String sectionLabel(VenueSection section) => venueSectionLabels[section]!;

VenueSection? sectionFromName(String? name) {
  for (final section in VenueSection.values) {
    if (section.name == name) return section;
  }
  return null;
}

enum AlbumKind { photo, video }

AlbumKind? albumKindFromName(String? name) {
  for (final kind in AlbumKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

/// Постоянный ID человека. Не зависит от места работы и не совпадает
/// с кодом заведения.
const personIdPattern = r'^AKYL-[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$';

const _personIdAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String createPersonId(Random random) {
  final chars = List<String>.generate(
    8,
    (_) => _personIdAlphabet[random.nextInt(_personIdAlphabet.length)],
  );
  return 'AKYL-${chars.join()}';
}

String tidyText(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String dateToJson(DateTime value) {
  final day = dateOnly(value);
  final month = day.month.toString().padLeft(2, '0');
  final dayText = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$month-$dayText';
}

DateTime? dateFromJson(Object? raw) {
  if (raw is! String) return null;
  final parts = raw.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

/// Место работы в личном профиле. Человек добавляет его сам.
/// [endedAt] == null значит «работаю сейчас».
/// Подтверждение владельца — отдельный признак, не допуск в заведение.
class WorkPlace {
  final String id;
  final String venueName;
  final HospitalityRole role;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool confirmed;
  final String? confirmedByOwnerId;

  const WorkPlace({
    required this.id,
    required this.venueName,
    required this.role,
    required this.startedAt,
    required this.endedAt,
    required this.confirmed,
    required this.confirmedByOwnerId,
  });

  bool get workingNow => endedAt == null;

  WorkPlace copyWith({
    String? venueName,
    HospitalityRole? role,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
    bool? confirmed,
    String? confirmedByOwnerId,
    bool clearConfirmedBy = false,
  }) {
    return WorkPlace(
      id: id,
      venueName: venueName ?? this.venueName,
      role: role ?? this.role,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      confirmed: confirmed ?? this.confirmed,
      confirmedByOwnerId:
          clearConfirmedBy ? null : (confirmedByOwnerId ?? this.confirmedByOwnerId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueName': venueName,
        'role': role.name,
        'startedAt': dateToJson(startedAt),
        'endedAt': endedAt == null ? null : dateToJson(endedAt!),
        'confirmed': confirmed,
        'confirmedByOwnerId': confirmedByOwnerId,
      };

  static WorkPlace? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = map['id'];
    final venueName = map['venueName'];
    final role = roleFromName(map['role'] as String?);
    final startedAt = dateFromJson(map['startedAt']);
    if (id is! String || id.isEmpty) return null;
    if (venueName is! String || tidyText(venueName).isEmpty) return null;
    if (role == null || startedAt == null) return null;
    final endedRaw = map['endedAt'];
    final endedAt = endedRaw == null ? null : dateFromJson(endedRaw);
    if (endedRaw != null && endedAt == null) return null;
    final ownerId = map['confirmedByOwnerId'];
    return WorkPlace(
      id: id,
      venueName: tidyText(venueName),
      role: role,
      startedAt: startedAt,
      endedAt: endedAt,
      confirmed: map['confirmed'] == true,
      confirmedByOwnerId: ownerId is String && ownerId.isNotEmpty ? ownerId : null,
    );
  }
}

class Award {
  final String id;
  final String title;
  final String note;

  const Award({required this.id, required this.title, required this.note});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'note': note};

  static Award? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = map['id'];
    final title = map['title'];
    if (id is! String || id.isEmpty) return null;
    if (title is! String || tidyText(title).isEmpty) return null;
    final note = map['note'];
    return Award(
      id: id,
      title: tidyText(title),
      note: note is String ? tidyText(note) : '',
    );
  }
}

class AlbumItem {
  final String id;
  final AlbumKind kind;
  final String localPath;
  final int sizeBytes;
  final DateTime addedAt;

  const AlbumItem({
    required this.id,
    required this.kind,
    required this.localPath,
    required this.sizeBytes,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'localPath': localPath,
        'sizeBytes': sizeBytes,
        'addedAt': addedAt.toIso8601String(),
      };

  static AlbumItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = map['id'];
    final kind = albumKindFromName(map['kind'] as String?);
    final localPath = map['localPath'];
    final sizeBytes = map['sizeBytes'];
    final addedAt = DateTime.tryParse(map['addedAt'] as String? ?? '');
    if (id is! String || id.isEmpty) return null;
    if (kind == null) return null;
    if (localPath is! String || localPath.isEmpty) return null;
    if (sizeBytes is! int || sizeBytes < 0) return null;
    if (addedAt == null) return null;
    return AlbumItem(
      id: id,
      kind: kind,
      localPath: localPath,
      sizeBytes: sizeBytes,
      addedAt: addedAt,
    );
  }
}

/// Личный профиль человека общепита. Живёт со своим ID между местами работы.
class PersonProfile {
  final String id;
  final String name;
  final String? photoPath;
  final List<String> skills;
  final List<Award> awards;
  final List<WorkPlace> workplaces;
  final List<AlbumItem> album;
  final DateTime createdAt;

  const PersonProfile({
    required this.id,
    required this.name,
    required this.photoPath,
    required this.skills,
    required this.awards,
    required this.workplaces,
    required this.album,
    required this.createdAt,
  });

  PersonProfile copyWith({
    String? name,
    String? photoPath,
    bool clearPhoto = false,
    List<String>? skills,
    List<Award>? awards,
    List<WorkPlace>? workplaces,
    List<AlbumItem>? album,
  }) {
    return PersonProfile(
      id: id,
      name: name ?? this.name,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      skills: skills ?? this.skills,
      awards: awards ?? this.awards,
      workplaces: workplaces ?? this.workplaces,
      album: album ?? this.album,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoPath': photoPath,
        'skills': skills,
        'awards': awards.map((award) => award.toJson()).toList(),
        'workplaces': workplaces.map((place) => place.toJson()).toList(),
        'album': album.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  static PersonProfile? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = map['id'];
    final name = map['name'];
    final createdAt = DateTime.tryParse(map['createdAt'] as String? ?? '');
    if (id is! String || !RegExp(personIdPattern).hasMatch(id)) return null;
    if (name is! String || tidyText(name).isEmpty) return null;
    if (createdAt == null) return null;
    final photo = map['photoPath'];
    final skills = <String>[];
    final skillsRaw = map['skills'];
    if (skillsRaw is List) {
      for (final item in skillsRaw) {
        if (item is String && tidyText(item).isNotEmpty) {
          skills.add(tidyText(item));
        }
      }
    }
    final awards = _parseList(map['awards'], Award.tryParse);
    final workplaces = _parseList(map['workplaces'], WorkPlace.tryParse);
    final album = _parseList(map['album'], AlbumItem.tryParse);
    if (awards == null || workplaces == null || album == null) return null;
    return PersonProfile(
      id: id,
      name: tidyText(name),
      photoPath: photo is String && photo.isNotEmpty ? photo : null,
      skills: skills,
      awards: awards,
      workplaces: workplaces,
      album: album,
      createdAt: createdAt,
    );
  }
}

/// Заведение, которое этот профиль ведёт как владелец.
/// Не путать с кодами 01–05 и с PIN.
class OwnedVenue {
  final String id;
  final String name;
  final String ownerProfileId;
  final DateTime createdAt;

  const OwnedVenue({
    required this.id,
    required this.name,
    required this.ownerProfileId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerProfileId': ownerProfileId,
        'createdAt': createdAt.toIso8601String(),
      };

  static OwnedVenue? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = map['id'];
    final name = map['name'];
    final ownerProfileId = map['ownerProfileId'];
    final createdAt = DateTime.tryParse(map['createdAt'] as String? ?? '');
    if (id is! String || id.isEmpty) return null;
    if (name is! String || tidyText(name).isEmpty) return null;
    if (ownerProfileId is! String || ownerProfileId.isEmpty) return null;
    if (createdAt == null) return null;
    return OwnedVenue(
      id: id,
      name: tidyText(name),
      ownerProfileId: ownerProfileId,
      createdAt: createdAt,
    );
  }
}

/// Допуск конкретного человека в заведение. Создаёт владелец.
/// Имени и должности достаточно: личный профиль сотрудника здесь не заводится.
class VenueAccess {
  final String id;
  final String venueId;
  final String personName;
  final HospitalityRole position;
  final List<VenueSection> permissions;
  final String createdByOwnerId;
  final DateTime createdAt;

  const VenueAccess({
    required this.id,
    required this.venueId,
    required this.personName,
    required this.position,
    required this.permissions,
    required this.createdByOwnerId,
    required this.createdAt,
  });

  VenueAccess copyWith({
    String? personName,
    HospitalityRole? position,
    List<VenueSection>? permissions,
  }) {
    return VenueAccess(
      id: id,
      venueId: venueId,
      personName: personName ?? this.personName,
      position: position ?? this.position,
      permissions: permissions ?? this.permissions,
      createdByOwnerId: createdByOwnerId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueId': venueId,
        'personName': personName,
        'position': position.name,
        'permissions': permissions.map((item) => item.name).toList(),
        'createdByOwnerId': createdByOwnerId,
        'createdAt': createdAt.toIso8601String(),
      };

  static VenueAccess? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final id = map['id'];
    final venueId = map['venueId'];
    final personName = map['personName'];
    final position = roleFromName(map['position'] as String?);
    final createdByOwnerId = map['createdByOwnerId'];
    final createdAt = DateTime.tryParse(map['createdAt'] as String? ?? '');
    if (id is! String || id.isEmpty) return null;
    if (venueId is! String || venueId.isEmpty) return null;
    if (personName is! String || tidyText(personName).isEmpty) return null;
    if (position == null) return null;
    if (createdByOwnerId is! String || createdByOwnerId.isEmpty) return null;
    if (createdAt == null) return null;
    final permissions = <VenueSection>[];
    final rawPermissions = map['permissions'];
    if (rawPermissions is! List) return null;
    for (final item in rawPermissions) {
      final section = sectionFromName(item as String?);
      if (section == null || permissions.contains(section)) continue;
      permissions.add(section);
    }
    return VenueAccess(
      id: id,
      venueId: venueId,
      personName: tidyText(personName),
      position: position,
      permissions: permissions,
      createdByOwnerId: createdByOwnerId,
      createdAt: createdAt,
    );
  }
}

class PeopleSnapshot {
  static const storageVersion = 1;

  final int version;
  final PersonProfile? me;
  final List<OwnedVenue> ownedVenues;
  final List<VenueAccess> accesses;

  const PeopleSnapshot({
    required this.version,
    required this.me,
    required this.ownedVenues,
    required this.accesses,
  });

  static const empty = PeopleSnapshot(
    version: storageVersion,
    me: null,
    ownedVenues: [],
    accesses: [],
  );

  PeopleSnapshot copyWith({
    PersonProfile? me,
    bool clearMe = false,
    List<OwnedVenue>? ownedVenues,
    List<VenueAccess>? accesses,
  }) {
    return PeopleSnapshot(
      version: storageVersion,
      me: clearMe ? null : (me ?? this.me),
      ownedVenues: ownedVenues ?? this.ownedVenues,
      accesses: accesses ?? this.accesses,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'me': me?.toJson(),
        'ownedVenues': ownedVenues.map((venue) => venue.toJson()).toList(),
        'accesses': accesses.map((access) => access.toJson()).toList(),
      };

  /// null, если это не наша версия или JSON битый.
  /// Хранилище в этом случае файл не перезаписывает.
  static PeopleSnapshot? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    if (map['version'] != storageVersion) return null;
    final meRaw = map['me'];
    final PersonProfile? me;
    if (meRaw == null) {
      me = null;
    } else {
      me = PersonProfile.tryParse(meRaw);
      if (me == null) return null;
    }
    final venues = _parseList(map['ownedVenues'], OwnedVenue.tryParse);
    final accesses = _parseList(map['accesses'], VenueAccess.tryParse);
    if (venues == null || accesses == null) return null;
    return PeopleSnapshot(
      version: storageVersion,
      me: me,
      ownedVenues: venues,
      accesses: accesses,
    );
  }
}

List<T>? _parseList<T>(Object? raw, T? Function(Object? item) parse) {
  if (raw == null) return <T>[];
  if (raw is! List) return null;
  final result = <T>[];
  for (final item in raw) {
    final parsed = parse(item);
    if (parsed == null) return null;
    result.add(parsed);
  }
  return result;
}
