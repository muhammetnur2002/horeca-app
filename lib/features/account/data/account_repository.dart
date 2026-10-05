import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

/// Состояние облачного аккаунта владельца бизнеса.
/// Не путать с [AuthState] из features/auth — тот отвечает за локальный
/// PIN-доступ (админ/сотрудник) на конкретном устройстве.
class AccountState {
  final bool isLoggedIn;
  final String? uid;
  final String? email;
  final bool isLoading;
  final String? error;
  final bool emailVerified;

  const AccountState({
    this.isLoggedIn = false,
    this.uid,
    this.email,
    this.isLoading = false,
    this.error,
    this.emailVerified = false,
  });

  AccountState copyWith({
    bool? isLoggedIn,
    String? uid,
    String? email,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? emailVerified,
  }) {
    return AccountState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

class AccountRepository extends StateNotifier<AccountState> {
  // late (не field initializer!) — раньше здесь было
  // `= FirebaseAuth.instance` прямо в объявлении поля, а инициализаторы
  // полей выполняются ДО тела конструктора, то есть раньше try/catch ниже.
  // Из-за этого, если Firebase не смог инициализироваться (main.dart это
  // осознанно допускает — приложение обязано работать офлайн), сам вызов
  // FirebaseAuth.instance бросал необработанное исключение прямо при
  // создании репозитория и ронял старт всего приложения.
  late final FirebaseAuth _auth;
  final SharedPreferences _prefs;

  // Отдельный, чисто локальный флаг "на этом устройстве уже когда-то
  // входили в аккаунт". Нужен для того, чтобы кратковременная недоступность
  // Firebase при холодном старте (нет сети, VPN режет googleapis.com,
  // агрессивная очистка памяти на некоторых Android-прошивках) не
  // выкидывала пользователя обратно на экран входа — session Firebase Auth
  // сама восстановится в фоне, как только сеть появится, а до этого
  // человек продолжает работать локально как обычно.
  static const _everLoggedInKey = 'account_ever_logged_in';

  bool get everLoggedIn => _prefs.getBool(_everLoggedInKey) ?? false;

  AccountRepository(this._prefs) : super(const AccountState()) {
    // Firebase мог не успеть/не суметь инициализироваться на этом запуске
    // (main.dart оборачивает Firebase.initializeApp() в try/catch и не
    // валит старт приложения) — тогда FirebaseAuth.instance бросит
    // исключение. Раньше это было ничем не защищено.
    try {
      _auth = FirebaseAuth.instance;
      final user = _auth.currentUser;
      if (user != null) {
        state = AccountState(
          isLoggedIn: true,
          uid: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
        );
        _prefs.setBool(_everLoggedInKey, true);
      }
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          state = const AccountState();
        } else {
          state = state.copyWith(
            isLoggedIn: true,
            uid: user.uid,
            email: user.email,
            isLoading: false,
            clearError: true,
            emailVerified: user.emailVerified,
          );
          _prefs.setBool(_everLoggedInKey, true);
        }
      });
    } catch (e) {
      // Firebase недоступен прямо сейчас — не блокируем запуск приложения,
      // состояние аккаунта просто останется "не определено" на этот запуск.
    }
  }

  /// Регистрация нового владельца бизнеса по email/паролю.
  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Письмо с подтверждением — не блокирует использование приложения
      // (аккаунт и так работает офлайн-first), но позволяет пользователю
      // восстановить доступ, если он ошибся в написании почты.
      try {
        await cred.user?.sendEmailVerification();
      } catch (_) {}
      state = state.copyWith(
        isLoggedIn: true,
        uid: cred.user?.uid,
        email: cred.user?.email,
        isLoading: false,
        emailVerified: cred.user?.emailVerified ?? false,
      );
      await _prefs.setBool(_everLoggedInKey, true);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Не удалось зарегистрироваться. Проверьте интернет.');
      return false;
    }
  }

  /// Повторно отправить письмо для подтверждения email.
  Future<bool> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Перечитать статус верификации email с сервера (после того как
  /// пользователь перешёл по ссылке из письма).
  Future<void> refreshEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null) {
        state = state.copyWith(emailVerified: user.emailVerified);
      }
    } catch (_) {}
  }

  /// Вход в существующий аккаунт (в том числе с другого устройства).
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(
        isLoggedIn: true,
        uid: cred.user?.uid,
        email: cred.user?.email,
        isLoading: false,
      );
      await _prefs.setBool(_everLoggedInKey, true);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Не удалось войти. Проверьте интернет.');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _prefs.setBool(_everLoggedInKey, false);
    state = const AccountState();
  }

  /// Повторный ввод пароля аккаунта — используем как подтверждение перед
  /// разрушительными действиями (например, удаление заведения), а не
  /// полноценный вход. Не трогает текущую сессию, только проверяет пароль.
  Future<bool> verifyPassword(String password) async {
    try {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) return false;
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'invalid-email':
        return 'Некорректный email';
      case 'weak-password':
        return 'Пароль слишком простой (минимум 6 символов)';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      default:
        return 'Ошибка входа: ${e.message ?? e.code}';
    }
  }
}

final accountRepositoryProvider =
    StateNotifierProvider<AccountRepository, AccountState>((ref) {
  return AccountRepository(ref.watch(sharedPreferencesProvider));
});
