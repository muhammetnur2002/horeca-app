import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/core/db/ids.dart';

/// Суффикс ключей SharedPreferences/secure storage конкретного заведения.
/// Данные заведений теперь в базе; суффикс остаётся для PIN-кодов
/// и настроек входа, которые пока хранятся по-старому.
String venueKeySuffix(String code) => code == '01' ? '' : '_$code';

class Venue {
  /// id строки в базе. Пустой у заведений из облачного реестра, которые
  /// ещё не заведены на этом устройстве.
  final String id;
  final String code; // '01'..'05'
  final String name;
  const Venue({this.id = '', required this.code, required this.name});

  Map<String, dynamic> toJson() => {'code': code, 'name': name};
  factory Venue.fromJson(Map<String, dynamic> j) =>
      Venue(code: j['code'] as String, name: j['name'] as String? ?? 'Заведение');

  factory Venue.fromRow(VenueRow row) =>
      Venue(id: row.id, code: row.code, name: row.name);
}

class VenueState {
  final List<Venue> venues;
  final String activeVenueCode;
  const VenueState({required this.venues, required this.activeVenueCode});

  Venue? get active {
    final matches = venues.where((v) => v.code == activeVenueCode);
    return matches.isEmpty ? null : matches.first;
  }

  bool get isMultiVenue => venues.length > 1;

  VenueState copyWith({List<Venue>? venues, String? activeVenueCode}) => VenueState(
        venues: venues ?? this.venues,
        activeVenueCode: activeVenueCode ?? this.activeVenueCode,
      );
}

/// Заведения устройства. Список хранится в базе и загружается до запуска
/// интерфейса (см. main.dart), поэтому состояние доступно сразу. Какое
/// заведение открыто — настройка устройства, она остаётся в SharedPreferences.
class VenueRepository extends StateNotifier<VenueState> {
  final SharedPreferences _prefs;
  final CatalogDao _dao;
  static const _secureStorage = FlutterSecureStorage();
  static const _activeKey = 'active_venue_code';
  static const maxVenues = 5;
  static const allCodes = ['01', '02', '03', '04', '05'];

  VenueRepository(this._prefs, this._dao, List<Venue> initialVenues)
      : super(VenueState(
          venues: initialVenues,
          activeVenueCode: _resolveActive(_prefs, initialVenues),
        ));

  static String _resolveActive(SharedPreferences prefs, List<Venue> venues) {
    final saved = prefs.getString(_activeKey);
    if (saved != null && venues.any((v) => v.code == saved)) return saved;
    return venues.isEmpty ? '01' : venues.first.code;
  }

  /// Загружает заведения из базы; если их нет — заводит пустое "01".
  static Future<List<Venue>> loadInitial(CatalogDao dao) async {
    var rows = await dao.loadVenues();
    if (rows.isEmpty) {
      await dao.upsertVenue(code: '01', name: 'Моё заведение');
      rows = await dao.loadVenues();
    }
    return rows.map(Venue.fromRow).toList();
  }

  /// Свободный код для нового заведения (null, если уже занято все 5).
  String? get nextFreeCode {
    for (final c in allCodes) {
      if (!state.venues.any((v) => v.code == c)) return c;
    }
    return null;
  }

  /// Новое заведение заводится пустым — без демонстрационных данных.
  bool addVenue(String name) {
    final code = nextFreeCode;
    if (code == null || name.trim().isEmpty) return false;
    final id = Ids.newId();
    _dao.upsertVenue(
        id: id, code: code, name: name.trim(), reportName: name.trim());
    state = state.copyWith(
        venues: [...state.venues, Venue(id: id, code: code, name: name.trim())]);
    return true;
  }

  void renameVenue(String code, String newName) {
    if (newName.trim().isEmpty) return;
    final venue = findByCode(code);
    if (venue == null) return;
    _dao.updateVenue(venue.id, name: newName.trim());
    state = state.copyWith(
      venues: state.venues
          .map((v) => v.code == code
              ? Venue(id: v.id, code: code, name: newName.trim())
              : v)
          .toList(),
    );
  }

  Venue? findByCode(String code) {
    final matches = state.venues.where((v) => v.code == code);
    return matches.isEmpty ? null : matches.first;
  }

  void setActiveVenue(String code) {
    _prefs.setString(_activeKey, code);
    state = state.copyWith(activeVenueCode: code);
  }

  /// Удаляет заведение с этого устройства: данные в базе (мягко) и PIN-коды.
  /// Последнее оставшееся заведение удалить нельзя.
  Future<bool> deleteVenue(String code) async {
    if (state.venues.length <= 1) return false;
    final venue = findByCode(code);
    if (venue == null) return false;

    await _dao.deleteVenue(venue.id);
    final suffix = venueKeySuffix(code);
    for (final key in [
      'pins_enabled',
      'pin_failed_attempts',
      'pin_locked_until',
    ]) {
      await _prefs.remove('$key$suffix');
    }
    try {
      await _secureStorage.delete(key: 'admin_pin$suffix');
      await _secureStorage.delete(key: 'staff_pin$suffix');
    } catch (_) {}

    final updated = state.venues.where((v) => v.code != code).toList();
    final newActive =
        state.activeVenueCode == code ? updated.first.code : state.activeVenueCode;
    if (newActive != state.activeVenueCode) {
      await _prefs.setString(_activeKey, newActive);
    }
    state = VenueState(venues: updated, activeVenueCode: newActive);
    return true;
  }

  /// Добавляет заведения из облачного реестра, которых ещё нет на этом
  /// устройстве (вход в аккаунт на новом телефоне). Заводятся пустыми.
  void mergeFromCloud(List<Venue> cloudVenues) {
    final localCodes = state.venues.map((v) => v.code).toSet();
    final added = <Venue>[];
    for (final v in cloudVenues) {
      if (localCodes.contains(v.code) || !allCodes.contains(v.code)) continue;
      final id = Ids.newId();
      _dao.upsertVenue(id: id, code: v.code, name: v.name, reportName: v.name);
      added.add(Venue(id: id, code: v.code, name: v.name));
    }
    if (added.isEmpty) return;
    state = state.copyWith(venues: [...state.venues, ...added]);
  }
}

/// Заведения, загруженные до запуска интерфейса (переопределяется в main).
final initialVenuesProvider = Provider<List<Venue>>((ref) {
  throw UnimplementedError('Must be initialized in main');
});

final venueRepositoryProvider = StateNotifierProvider<VenueRepository, VenueState>((ref) {
  return VenueRepository(
    ref.watch(sharedPreferencesProvider),
    ref.watch(catalogDaoProvider),
    ref.watch(initialVenuesProvider),
  );
});

/// id активного заведения в базе.
final activeVenueIdProvider = Provider<String>((ref) {
  final state = ref.watch(venueRepositoryProvider);
  return state.active?.id ?? state.venues.first.id;
});
