import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';

// flutter_secure_storage дёргает нативный платформенный канал — в юнит-тестах
// нативной стороны нет, поэтому подсовываем пустой мок-обработчик, чтобы
// AuthRepository мог нормально создаться (иначе первый же read() упадёт
// с MissingPluginException).
const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
      switch (call.method) {
        case 'read':
          return null;
        case 'readAll':
          return <String, String>{};
        case 'write':
        case 'delete':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  test('после 5 неверных попыток подряд ввод PIN блокируется', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepository(prefs, '01');

    for (var i = 0; i < 5; i++) {
      expect(repo.checkPin('0000'), isNull);
    }

    expect(repo.lockoutSecondsRemaining, greaterThan(0));
    // Пока действует блокировка, даже пустой/любой ввод не проверяется.
    expect(repo.checkPin('1234'), isNull);
  });

  test('верный PIN сбрасывает счётчик неверных попыток', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepository(prefs, '01');
    await repo.setAdminPin('1234');

    for (var i = 0; i < 4; i++) {
      repo.checkPin('9999');
    }
    expect(repo.checkPin('1234'), UserRole.admin);

    // После успешного входа новых 4 неверных попыток недостаточно для
    // блокировки — счётчик должен был обнулиться при успехе.
    for (var i = 0; i < 4; i++) {
      repo.checkPin('9999');
    }
    expect(repo.lockoutSecondsRemaining, 0);
  });

  test('длина полного ввода берётся из сохранённых PIN', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepository(prefs, '01');
    expect(repo.fullPinLength, 4);
    expect(repo.shortestPinLength, 4);

    await repo.setAdminPin('123456');
    await repo.setStaffPin('5678');
    expect(repo.fullPinLength, 6);
    expect(repo.shortestPinLength, 4);
    expect(repo.shouldCountOnErase('999'), isFalse);
    expect(repo.shouldCountOnErase('9999'), isTrue);
    expect(repo.shouldCountOnErase('5678'), isFalse);
  });

  test('промежуточная проверка PIN не тратит попытку', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepository(prefs, '01');
    await repo.setAdminPin('123456');

    expect(repo.peekPin('1234'), isNull);
    expect(repo.peekPin('12345'), isNull);
    expect(repo.attemptsRemaining, 5);
    expect(repo.peekPin('123456'), UserRole.admin);
    expect(repo.attemptsRemaining, 5);
  });

  test('неверный PIN не путается с ролью staff', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepository(prefs, '01');
    await repo.setAdminPin('1111');
    await repo.setStaffPin('2222');

    expect(repo.checkPin('1111'), UserRole.admin);
    expect(repo.checkPin('2222'), UserRole.staff);
    expect(repo.checkPin('3333'), isNull);
  });
}
