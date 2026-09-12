import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

enum UserRole { admin, staff }

class AuthState {
  final bool isLoggedIn;
  final UserRole? role;
  final String? userName;

  /// Включена ли защита PIN-кодом. Хранится в состоянии, а не читается из
  /// prefs на лету: иначе включение/отключение защиты не перерисовывало UI.
  final bool pinsEnabled;

  const AuthState({
    this.isLoggedIn = false,
    this.role,
    this.userName,
    this.pinsEnabled = false,
  });

  /// Пока PIN-коды не настроены, все функции доступны без ограничений.
  bool get isAdmin => !pinsEnabled || role != UserRole.staff;

  AuthState copyWith({
    bool? isLoggedIn,
    UserRole? role,
    String? userName,
    bool? pinsEnabled,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        role: role ?? this.role,
        userName: userName ?? this.userName,
        pinsEnabled: pinsEnabled ?? this.pinsEnabled,
      );
}

class AuthRepository extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  static const _adminPinKey = 'admin_pin';
  static const _staffPinKey = 'staff_pin';
  static const _pinsEnabledKey = 'pins_enabled';

  AuthRepository(this._prefs)
      : super(AuthState(
            pinsEnabled: _prefs.getBool(_pinsEnabledKey) ?? false));

  bool get pinsEnabled => state.pinsEnabled;
  String? get adminPin => _prefs.getString(_adminPinKey);
  String? get staffPin => _prefs.getString(_staffPinKey);

  void setPinsEnabled(bool enabled) {
    _prefs.setBool(_pinsEnabledKey, enabled);
    state = state.copyWith(pinsEnabled: enabled);
  }

  void setAdminPin(String pin) {
    _prefs.setString(_adminPinKey, pin);
  }

  void setStaffPin(String pin) {
    _prefs.setString(_staffPinKey, pin);
  }

  void clearPins() {
    _prefs.remove(_adminPinKey);
    _prefs.remove(_staffPinKey);
    _prefs.setBool(_pinsEnabledKey, false);
    state = const AuthState(pinsEnabled: false);
  }

  UserRole? checkPin(String pin) {
    final admin = adminPin;
    final staff = staffPin;
    if (admin != null && admin.isNotEmpty && pin == admin) {
      return UserRole.admin;
    }
    if (staff != null && staff.isNotEmpty && pin == staff) {
      return UserRole.staff;
    }
    return null;
  }

  void login(UserRole role, {String? userName}) {
    state = AuthState(
      isLoggedIn: true,
      role: role,
      userName: userName,
      pinsEnabled: state.pinsEnabled,
    );
  }

  /// Блокирует приложение: следующий вход снова потребует PIN-код.
  void logout() {
    state = AuthState(pinsEnabled: state.pinsEnabled);
  }
}

final authRepositoryProvider =
    StateNotifierProvider<AuthRepository, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(prefs);
});
