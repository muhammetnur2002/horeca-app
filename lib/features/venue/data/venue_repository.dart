import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

/// Суффикс для ключей SharedPreferences/secure storage конкретного заведения.
/// Заведение "01" — это те же ключи, что использовались до появления
/// мультизаведений (settings_data, history_data, ...), поэтому у существующих
/// пользователей ничего не переносится и не теряется при обновлении.
/// Заведения "02".."05" получают отдельные ключи с суффиксом.
String venueKeySuffix(String code) => code == '01' ? '' : '_$code';

class Venue {
  final String code; // '01'..'05'
  final String name;
  const Venue({required this.code, required this.name});

  Map<String, dynamic> toJson() => {'code': code, 'name': name};
  factory Venue.fromJson(Map<String, dynamic> j) =>
      Venue(code: j['code'] as String, name: j['name'] as String? ?? 'Заведение');
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

class VenueRepository extends StateNotifier<VenueState> {
  final SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();
  static const _venuesKey = 'venues_list';
  static const _activeKey = 'active_venue_code';
  static const maxVenues = 5;
  static const allCodes = ['01', '02', '03', '04', '05'];

  VenueRepository(this._prefs)
      : super(const VenueState(venues: [], activeVenueCode: '01')) {
    _load();
  }

  void _load() {
    final jsonString = _prefs.getString(_venuesKey);
    List<Venue> venues;
    if (jsonString == null) {
      // Первый запуск после обновления: заводим заведение "01" без переноса
      // данных — оно само указывает на уже существующие ключи.
      venues = [Venue(code: '01', name: _legacyName() ?? 'Моё заведение')];
      _saveVenues(venues);
    } else {
      try {
        final List<dynamic> data = jsonDecode(jsonString);
        venues = data.map((e) => Venue.fromJson(e as Map<String, dynamic>)).toList();
        if (venues.isEmpty) {
          venues = [Venue(code: '01', name: _legacyName() ?? 'Моё заведение')];
        }
      } catch (_) {
        venues = [Venue(code: '01', name: _legacyName() ?? 'Моё заведение')];
      }
    }
    final active = _prefs.getString(_activeKey) ?? '01';
    state = VenueState(venues: venues, activeVenueCode: active);
  }

  String? _legacyName() {
    try {
      final raw = _prefs.getString('settings_data');
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data['establishmentName'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _saveVenues(List<Venue> venues) {
    _prefs.setString(_venuesKey, jsonEncode(venues.map((v) => v.toJson()).toList()));
  }

  /// Свободный код для нового заведения (null, если уже занято все 5).
  String? get nextFreeCode {
    for (final c in allCodes) {
      if (!state.venues.any((v) => v.code == c)) return c;
    }
    return null;
  }

  bool addVenue(String name) {
    final code = nextFreeCode;
    if (code == null || name.trim().isEmpty) return false;
    final updated = [...state.venues, Venue(code: code, name: name.trim())];
    _saveVenues(updated);
    state = state.copyWith(venues: updated);
    return true;
  }

  void renameVenue(String code, String newName) {
    if (newName.trim().isEmpty) return;
    final updated = state.venues
        .map((v) => v.code == code ? Venue(code: code, name: newName.trim()) : v)
        .toList();
    _saveVenues(updated);
    state = state.copyWith(venues: updated);
  }

  Venue? findByCode(String code) {
    final matches = state.venues.where((v) => v.code == code);
    return matches.isEmpty ? null : matches.first;
  }

  void setActiveVenue(String code) {
    _prefs.setString(_activeKey, code);
    state = state.copyWith(activeVenueCode: code);
  }

  /// Безвозвратно удаляет заведение с этого устройства: локальные данные
  /// (SharedPreferences) и PIN-коды (secure storage). Облачную копию нужно
  /// удалить отдельно через CloudSyncService.deleteVenueCloud — репозиторий
  /// сам с сетью не работает. Нельзя удалить последнее оставшееся заведение
  /// аккаунта — всегда должно остаться хотя бы одно.
  Future<bool> deleteVenue(String code) async {
    if (state.venues.length <= 1) return false;
    if (!state.venues.any((v) => v.code == code)) return false;

    final suffix = venueKeySuffix(code);
    for (final key in [
      'settings_data',
      'history_data',
      'shift_records',
      'notification_data',
      'cloud_sync_last_known_update_ms',
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
    _saveVenues(updated);
    final newActive =
        state.activeVenueCode == code ? updated.first.code : state.activeVenueCode;
    if (newActive != state.activeVenueCode) {
      await _prefs.setString(_activeKey, newActive);
    }
    state = VenueState(venues: updated, activeVenueCode: newActive);
    return true;
  }

  /// Добавляет в локальный список заведения, которые уже есть в облачном
  /// реестре, но ещё не заведены на этом устройстве (например, вход в
  /// аккаунт на новом телефоне). Сами данные заведения при этом не
  /// скачиваются — только код и название, чтобы PIN-экран знал, что такой
  /// код существует.
  void mergeFromCloud(List<Venue> cloudVenues) {
    final localCodes = state.venues.map((v) => v.code).toSet();
    final toAdd = cloudVenues.where((v) => !localCodes.contains(v.code)).toList();
    if (toAdd.isEmpty) return;
    final updated = [...state.venues, ...toAdd];
    _saveVenues(updated);
    state = state.copyWith(venues: updated);
  }
}

final venueRepositoryProvider = StateNotifierProvider<VenueRepository, VenueState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return VenueRepository(prefs);
});
