import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

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
  static const _adminPinKey = 'admin_pin';
  static const _staffPinKey = 'staff_pin';
  static const _pinsEnabledKey = 'pins_enabled';

  AuthRepository(this._prefs) : super(const AuthState());

  bool get pinsEnabled => _prefs.getBool(_pinsEnabledKey) ?? false;
  String? get adminPin => _prefs.getString(_adminPinKey);
  String? get staffPin => _prefs.getString(_staffPinKey);

  void setPinsEnabled(bool enabled) {
    _prefs.setBool(_pinsEnabledKey, enabled);
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
  }

  UserRole? checkPin(String pin) {
    if (pin == adminPin) return UserRole.admin;
    if (pin == staffPin) return UserRole.staff;
    return null;
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
  return AuthRepository(prefs);
});