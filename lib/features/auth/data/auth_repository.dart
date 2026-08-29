import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { admin, staff }

/// Состояние авторизации.
///
/// [pinsEnabled] хранится прямо в состоянии, чтобы UI перестраивался при
/// включении/выключении защиты (раньше читалось через notifier и не обновлялось).
class AuthState {
  final bool isLoggedIn;
  final UserRole? role;
  final String? userName;
  final bool pinsEnabled;
  final bool pinsConfigured;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const AuthState({
    this.isLoggedIn = false,
    this.role,
    this.userName,
    this.pinsEnabled = false,
    this.pinsConfigured = false,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  /// Доступ к админским разделам (настройки, аналитика, iiko, шаблоны).
  ///
  /// Если защита PIN-кодом выключена — приложение работает в
  /// однопользовательском режиме и доступ открыт. Если включена — доступ
  /// строго по роли администратора (fail-closed: неизвестная роль = отказ).
  bool get hasAdminAccess => !pinsEnabled || role == UserRole.admin;

  /// Требуется ли экран ввода PIN прямо сейчас.
  bool get needsAuthentication => pinsEnabled && pinsConfigured && !isLoggedIn;

  Duration get lockRemaining {
    final until = lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isLocked => lockRemaining > Duration.zero;

  AuthState copyWith({
    bool? isLoggedIn,
    UserRole? role,
    String? userName,
    bool? pinsEnabled,
    bool? pinsConfigured,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearRole = false,
    bool clearUserName = false,
    bool clearLock = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: clearRole ? null : (role ?? this.role),
      userName: clearUserName ? null : (userName ?? this.userName),
      pinsEnabled: pinsEnabled ?? this.pinsEnabled,
      pinsConfigured: pinsConfigured ?? this.pinsConfigured,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

class AuthRepository extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;

  static const _adminHashKey = 'admin_pin_hash';
  static const _staffHashKey = 'staff_pin_hash';
  static const _saltKey = 'pin_salt';
  static const _maxLenKey = 'pin_max_len';
  static const _pinsEnabledKey = 'pins_enabled';
  static const _failedKey = 'pin_failed_attempts';
  static const _lockedUntilKey = 'pin_locked_until';

  // Ключи старого формата (PIN открытым текстом) — только для миграции.
  static const _legacyAdminKey = 'admin_pin';
  static const _legacyStaffKey = 'staff_pin';

  /// Сколько неверных попыток допускается до блокировки.
  static const maxAttempts = 5;

  /// Базовая длительность блокировки; удваивается с каждой следующей серией.
  static const baseLockout = Duration(seconds: 30);
  static const maxLockout = Duration(minutes: 15);

  AuthRepository(this._prefs) : super(const AuthState()) {
    _migrateLegacyPins();
    _restore();
  }

  // ── Хеширование ───────────────────────────────────────────────────────────

  String get _salt {
    var salt = _prefs.getString(_saltKey);
    if (salt == null || salt.isEmpty) {
      final rnd = Random.secure();
      final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
      salt = base64Url.encode(bytes);
      _prefs.setString(_saltKey, salt);
    }
    return salt;
  }

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  /// Сравнение за постоянное время — не даёт измерить совпадение по префиксу.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ── Миграция и восстановление ─────────────────────────────────────────────

  /// Переводит PIN-коды из старого открытого формата в хеши и удаляет
  /// открытые значения. Выполняется один раз при первом запуске новой версии.
  void _migrateLegacyPins() {
    final legacyAdmin = _prefs.getString(_legacyAdminKey);
    final legacyStaff = _prefs.getString(_legacyStaffKey);
    if (legacyAdmin == null && legacyStaff == null) return;

    final salt = _salt;
    var maxLen = 0;
    if (legacyAdmin != null && legacyAdmin.isNotEmpty) {
      _prefs.setString(_adminHashKey, _hash(legacyAdmin, salt));
      maxLen = max(maxLen, legacyAdmin.length);
    }
    if (legacyStaff != null && legacyStaff.isNotEmpty) {
      _prefs.setString(_staffHashKey, _hash(legacyStaff, salt));
      maxLen = max(maxLen, legacyStaff.length);
    }
    if (maxLen > 0) _prefs.setInt(_maxLenKey, maxLen);
    _prefs.remove(_legacyAdminKey);
    _prefs.remove(_legacyStaffKey);
  }

  void _restore() {
    final lockedMs = _prefs.getInt(_lockedUntilKey);
    state = AuthState(
      pinsEnabled: _prefs.getBool(_pinsEnabledKey) ?? false,
      pinsConfigured: _prefs.getString(_adminHashKey) != null,
      failedAttempts: _prefs.getInt(_failedKey) ?? 0,
      lockedUntil:
          lockedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lockedMs),
    );
  }

  // ── Настройка PIN-кодов ───────────────────────────────────────────────────

  bool get pinsEnabled => state.pinsEnabled;
  bool get pinsConfigured => state.pinsConfigured;

  /// Максимальная длина настроенного PIN — экран ввода по ней понимает,
  /// когда попытка считается завершённой.
  int get pinMaxLength => _prefs.getInt(_maxLenKey) ?? 6;

  void setPins({required String adminPin, required String staffPin}) {
    final salt = _salt;
    _prefs.setString(_adminHashKey, _hash(adminPin, salt));
    _prefs.setString(_staffHashKey, _hash(staffPin, salt));
    _prefs.setInt(_maxLenKey, max(adminPin.length, staffPin.length));
    _prefs.setBool(_pinsEnabledKey, true);
    _clearAttempts();
    state = state.copyWith(
      pinsEnabled: true,
      pinsConfigured: true,
      failedAttempts: 0,
      clearLock: true,
    );
  }

  void clearPins() {
    _prefs.remove(_adminHashKey);
    _prefs.remove(_staffHashKey);
    _prefs.remove(_maxLenKey);
    _prefs.setBool(_pinsEnabledKey, false);
    _clearAttempts();
    state = const AuthState();
  }

  // ── Вход ──────────────────────────────────────────────────────────────────

  /// Проверяет PIN. Возвращает роль при совпадении, иначе null.
  /// Блокировку и счётчик попыток не трогает — этим управляет [registerFailure].
  UserRole? checkPin(String pin) {
    if (state.isLocked) return null;
    final salt = _salt;
    final hash = _hash(pin, salt);

    final adminHash = _prefs.getString(_adminHashKey);
    if (adminHash != null && _constantTimeEquals(hash, adminHash)) {
      return UserRole.admin;
    }
    final staffHash = _prefs.getString(_staffHashKey);
    if (staffHash != null && _constantTimeEquals(hash, staffHash)) {
      return UserRole.staff;
    }
    return null;
  }

  /// Регистрирует неудачную попытку и при необходимости включает блокировку.
  void registerFailure() {
    final attempts = state.failedAttempts + 1;
    _prefs.setInt(_failedKey, attempts);

    if (attempts % maxAttempts == 0) {
      final series = attempts ~/ maxAttempts;
      var lockMs = baseLockout.inMilliseconds * pow(2, series - 1).toInt();
      if (lockMs > maxLockout.inMilliseconds) lockMs = maxLockout.inMilliseconds;
      final until = DateTime.now().add(Duration(milliseconds: lockMs));
      _prefs.setInt(_lockedUntilKey, until.millisecondsSinceEpoch);
      state = state.copyWith(failedAttempts: attempts, lockedUntil: until);
    } else {
      state = state.copyWith(failedAttempts: attempts);
    }
  }

  void _clearAttempts() {
    _prefs.remove(_failedKey);
    _prefs.remove(_lockedUntilKey);
  }

  void login(UserRole role, {String? userName}) {
    _clearAttempts();
    state = state.copyWith(
      isLoggedIn: true,
      role: role,
      userName: userName,
      failedAttempts: 0,
      clearLock: true,
    );
  }

  void logout() {
    state = state.copyWith(
      isLoggedIn: false,
      clearRole: true,
      clearUserName: true,
    );
  }
}

final authRepositoryProvider =
    StateNotifierProvider<AuthRepository, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(prefs);
});
