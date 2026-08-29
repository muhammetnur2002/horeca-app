import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('Хранение PIN', () {
    test('PIN не сохраняется открытым текстом', () async {
      final prefs = await prefsWith({});
      AuthRepository(prefs).setPins(adminPin: '1234', staffPin: '5678');

      expect(prefs.getString('admin_pin'), isNull);
      expect(prefs.getString('staff_pin'), isNull);
      final hash = prefs.getString('admin_pin_hash');
      expect(hash, isNotNull);
      expect(hash, isNot('1234'));
      expect(hash!.length, 64); // sha256 в hex
    });

    test('одинаковые PIN у разных установок дают разные хеши (соль)', () async {
      final a = await prefsWith({});
      AuthRepository(a).setPins(adminPin: '1234', staffPin: '5678');
      final hashA = a.getString('admin_pin_hash');

      final b = await prefsWith({});
      AuthRepository(b).setPins(adminPin: '1234', staffPin: '5678');
      final hashB = b.getString('admin_pin_hash');

      expect(hashA, isNot(hashB));
    });

    test('старые открытые PIN мигрируют в хеши и удаляются', () async {
      final prefs = await prefsWith({
        'admin_pin': '4321',
        'staff_pin': '8765',
        'pins_enabled': true,
      });
      final repo = AuthRepository(prefs);

      expect(prefs.getString('admin_pin'), isNull);
      expect(prefs.getString('staff_pin'), isNull);
      expect(repo.checkPin('4321'), UserRole.admin);
      expect(repo.checkPin('8765'), UserRole.staff);
    });
  });

  group('Проверка PIN', () {
    test('верный код возвращает роль, неверный — null', () async {
      final repo = AuthRepository(await prefsWith({}))
        ..setPins(adminPin: '1234', staffPin: '5678');

      expect(repo.checkPin('1234'), UserRole.admin);
      expect(repo.checkPin('5678'), UserRole.staff);
      expect(repo.checkPin('0000'), isNull);
    });
  });

  group('Защита от перебора', () {
    test('после maxAttempts неудач вход блокируется', () async {
      final repo = AuthRepository(await prefsWith({}))
        ..setPins(adminPin: '1234', staffPin: '5678');

      for (var i = 0; i < AuthRepository.maxAttempts; i++) {
        expect(repo.state.isLocked, isFalse, reason: 'попытка $i');
        repo.registerFailure();
      }

      expect(repo.state.isLocked, isTrue);
      expect(repo.checkPin('1234'), isNull,
          reason: 'во время блокировки даже верный код не принимается');
    });

    test('блокировка переживает перезапуск приложения', () async {
      final prefs = await prefsWith({});
      final repo = AuthRepository(prefs)
        ..setPins(adminPin: '1234', staffPin: '5678');
      for (var i = 0; i < AuthRepository.maxAttempts; i++) {
        repo.registerFailure();
      }

      final restarted = AuthRepository(prefs);
      expect(restarted.state.isLocked, isTrue);
    });

    test('успешный вход сбрасывает счётчик', () async {
      final repo = AuthRepository(await prefsWith({}))
        ..setPins(adminPin: '1234', staffPin: '5678');
      repo.registerFailure();
      repo.registerFailure();
      repo.login(UserRole.admin);

      expect(repo.state.failedAttempts, 0);
      expect(repo.state.isLocked, isFalse);
    });
  });

  group('Права доступа', () {
    test('без PIN-кодов доступ открыт (однопользовательский режим)', () {
      const state = AuthState();
      expect(state.hasAdminAccess, isTrue);
    });

    test('с включёнными PIN неизвестная роль не даёт доступ (fail-closed)', () {
      const state = AuthState(pinsEnabled: true, isLoggedIn: false);
      expect(state.hasAdminAccess, isFalse);
    });

    test('сотрудник не получает админский доступ', () {
      const state =
          AuthState(pinsEnabled: true, isLoggedIn: true, role: UserRole.staff);
      expect(state.hasAdminAccess, isFalse);
    });

    test('администратор получает доступ', () {
      const state =
          AuthState(pinsEnabled: true, isLoggedIn: true, role: UserRole.admin);
      expect(state.hasAdminAccess, isTrue);
    });
  });

  test('logout сбрасывает роль', () async {
    final repo = AuthRepository(await prefsWith({}))
      ..setPins(adminPin: '1234', staffPin: '5678')
      ..login(UserRole.admin);
    expect(repo.state.role, UserRole.admin);

    repo.logout();
    expect(repo.state.role, isNull);
    expect(repo.state.isLoggedIn, isFalse);
  });
}
