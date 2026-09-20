import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

enum UserRole { admin, staff }

class AuthState {
  final bool isLoggedIn;
  final UserRole? role;
  final String? userName;

  const AuthState({this.isLoggedIn = false, this.role, this.userName});

  AuthState copyWith({bool? isLoggedIn, UserRole? role, String? userName}) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        role: role ?? this.role,
        userName: userName ?? this.userName,
      );
}

class AuthRepository extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();
  final String _adminPinKey;
  final String _staffPinKey;
  final String _pinsEnabledKey;
  final String _failedAttemptsKey;
  final String _lockedUntilKey;

  // PIN-коды — это ключи доступа к админ-функциям, поэтому храним их в
  // защищённом (шифрованном) хранилище, а не в обычных SharedPreferences.
  // Кэшируем в памяти, чтобы checkPin() оставался синхронным (нужно для
  // мгновенного ввода PIN на экране входа).
  String? _cachedAdminPin;
  String? _cachedStaffPin;
  bool _pinsLoaded = false;
  final Completer<void> _pinsLoadedCompleter = Completer<void>();

  AuthRepository(this._prefs, String venueCode)
      : _adminPinKey = 'admin_pin${venueKeySuffix(venueCode)}',
        _staffPinKey = 'staff_pin${venueKeySuffix(venueCode)}',
        _pinsEnabledKey = 'pins_enabled${venueKeySuffix(venueCode)}',
        _failedAttemptsKey = 'pin_failed_attempts${venueKeySuffix(venueCode)}',
        _lockedUntilKey = 'pin_locked_until${venueKeySuffix(venueCode)}',
        super(const AuthState()) {
    _loadPins();
  }

  Future<void> _loadPins() async {
    try {
      _cachedAdminPin = await _secureStorage.read(key: _adminPinKey);
      _cachedStaffPin = await _secureStorage.read(key: _staffPinKey);
    } catch (_) {
      _cachedAdminPin = null;
      _cachedStaffPin = null;
    }
    _pinsLoaded = true;
    if (!_pinsLoadedCompleter.isCompleted) _pinsLoadedCompleter.complete();
  }

  bool get pinsEnabled => _prefs.getBool(_pinsEnabledKey) ?? false;
  bool get pinsLoaded => _pinsLoaded;
  String? get adminPin => _cachedAdminPin;
  String? get staffPin => _cachedStaffPin;

  /// Завершается, когда PIN-коды текущего заведения реально прочитаны из
  /// secure storage. Нужно перед показом adminPin/staffPin в UI (например
  /// PinSettingsScreen) сразу после переключения заведения — иначе экземпляр
  /// AuthRepository только что создан и adminPin/staffPin ещё null, хотя
  /// PIN-коды на самом деле сохранены.
  Future<void> get pinsReady =>
      _pinsLoaded ? Future.value() : _pinsLoadedCompleter.future;

  void setPinsEnabled(bool enabled) {
    _prefs.setBool(_pinsEnabledKey, enabled);
  }

  Future<void> setAdminPin(String pin) async {
    _cachedAdminPin = pin;
    await _secureStorage.write(key: _adminPinKey, value: pin);
  }

  Future<void> setStaffPin(String pin) async {
    _cachedStaffPin = pin;
    await _secureStorage.write(key: _staffPinKey, value: pin);
  }

  Future<void> clearPins() async {
    _cachedAdminPin = null;
    _cachedStaffPin = null;
    await _secureStorage.delete(key: _adminPinKey);
    await _secureStorage.delete(key: _staffPinKey);
    _prefs.setBool(_pinsEnabledKey, false);
  }

  // Защита от подбора PIN: после нескольких неверных попыток подряд —
  // временная блокировка ввода. Храним в SharedPreferences (не в памяти),
  // чтобы блокировка не сбрасывалась при переключении между заведениями
  // или перезапуске приложения.
  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(seconds: 30);

  int get _failedAttempts => _prefs.getInt(_failedAttemptsKey) ?? 0;
  set _failedAttempts(int v) => _prefs.setInt(_failedAttemptsKey, v);

  DateTime? get _lockedUntil {
    final ms = _prefs.getInt(_lockedUntilKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  set _lockedUntil(DateTime? v) {
    if (v == null) {
      _prefs.remove(_lockedUntilKey);
    } else {
      _prefs.setInt(_lockedUntilKey, v.millisecondsSinceEpoch);
    }
  }

  /// Сколько секунд осталось до разблокировки ввода PIN (0, если не заблокировано).
  int get lockoutSecondsRemaining {
    final until = _lockedUntil;
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  UserRole? checkPin(String pin) {
    if (lockoutSecondsRemaining > 0) return null;
    if (pin.isEmpty) return null;
    if (pin == adminPin) {
      _failedAttempts = 0;
      return UserRole.admin;
    }
    if (pin == staffPin) {
      _failedAttempts = 0;
      return UserRole.staff;
    }
    _failedAttempts = _failedAttempts + 1;
    if (_failedAttempts >= _maxAttempts) {
      _lockedUntil = DateTime.now().add(_lockoutDuration);
      _failedAttempts = 0;
    }
    return null;
  }

  /// То же самое, но сначала дожидается, пока PIN-коды заведения реально
  /// прочитаются из secure storage — нужно при входе сразу после
  /// переключения на другое заведение (см. PinScreen), когда экземпляр
  /// AuthRepository мог быть создан только что.
  Future<UserRole?> checkPinReady(String pin) async {
    if (!_pinsLoaded) await _pinsLoadedCompleter.future;
    return checkPin(pin);
  }

  /// Проверка PIN администратора конкретного заведения без переключения
  /// активного заведения и без создания полноценного AuthRepository —
  /// нужно для подтверждения удаления заведения (см. VenueSettingsScreen).
  static Future<bool> checkAdminPinForVenue(String venueCode, String pin) async {
    if (pin.isEmpty) return false;
    try {
      final stored =
          await _secureStorage.read(key: 'admin_pin${venueKeySuffix(venueCode)}');
      return stored != null && stored == pin;
    } catch (_) {
      return false;
    }
  }

  // ── Настройка PIN произвольного (не обязательно активного) заведения ──────
  // PinSettingsScreen раньше переключал активное заведение через
  // VenueRepository.setActiveVenue() просто чтобы открыть форму настройки
  // PIN. Но authRepositoryProvider следит за активным заведением на самом
  // верхнем уровне (app.dart), поэтому переключение активного заведения
  // прямо посреди Настроек мгновенно меняло текущую сессию входа во всём
  // приложении — экран мог внезапно откатиться на ввод PIN. Эти статические
  // методы читают/пишут PIN конкретного заведения напрямую, без создания
  // AuthRepository и без смены активного заведения.
  static Future<String?> readAdminPinForVenue(String venueCode) async {
    try {
      return await _secureStorage.read(key: 'admin_pin${venueKeySuffix(venueCode)}');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> readStaffPinForVenue(String venueCode) async {
    try {
      return await _secureStorage.read(key: 'staff_pin${venueKeySuffix(venueCode)}');
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeAdminPinForVenue(String venueCode, String pin) =>
      _secureStorage.write(key: 'admin_pin${venueKeySuffix(venueCode)}', value: pin);

  static Future<void> writeStaffPinForVenue(String venueCode, String pin) =>
      _secureStorage.write(key: 'staff_pin${venueKeySuffix(venueCode)}', value: pin);

  static bool pinsEnabledForVenue(SharedPreferences prefs, String venueCode) =>
      prefs.getBool('pins_enabled${venueKeySuffix(venueCode)}') ?? false;

  static Future<void> setPinsEnabledForVenue(
      SharedPreferences prefs, String venueCode, bool enabled) async {
    await prefs.setBool('pins_enabled${venueKeySuffix(venueCode)}', enabled);
  }

  static Future<void> clearPinsForVenue(
      SharedPreferences prefs, String venueCode) async {
    try {
      await _secureStorage.delete(key: 'admin_pin${venueKeySuffix(venueCode)}');
      await _secureStorage.delete(key: 'staff_pin${venueKeySuffix(venueCode)}');
    } catch (_) {}
    await prefs.setBool('pins_enabled${venueKeySuffix(venueCode)}', false);
  }

  void login(UserRole role, {String? userName}) {
    state = AuthState(isLoggedIn: true, role: role, userName: userName);
  }

  void logout() {
    state = const AuthState();
  }
}

final authRepositoryProvider = StateNotifierProvider<AuthRepository, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final venueCode = ref.watch(venueRepositoryProvider).activeVenueCode;
  return AuthRepository(prefs, venueCode);
});
