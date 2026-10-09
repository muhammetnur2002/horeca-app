import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_screen.dart';

// Экран PIN целиком: замок «5 ошибок → 30 секунд» нельзя обойти,
// стирая последнюю цифру до того, как код набран до конца.
const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void _mockPins({required String admin, required String staff}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async {
    if (call.method != 'read') return null;
    final key = (call.arguments as Map)['key'] as String;
    if (key.startsWith('admin_pin')) return admin;
    if (key.startsWith('staff_pin')) return staff;
    return null;
  });
}

Future<ProviderContainer> _pumpPinScreen(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: PinScreen()),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(PinScreen)));
}

Future<void> _type(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    if (key == '<') {
      await tester.tap(find.byIcon(Icons.backspace_outlined));
    } else {
      await tester.tap(find.text(key).last);
    }
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  testWidgets('4 цифры, стереть, другая цифра — перебор упирается в замок',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    _mockPins(admin: '1234', staff: '5678');
    final container = await _pumpPinScreen(tester);

    for (var i = 0; i < 5; i++) {
      await _type(tester, '999$i');
      await _type(tester, '<');
    }

    expect(container.read(authRepositoryProvider.notifier).lockoutSecondsRemaining,
        greaterThan(0));
    expect(find.textContaining('Слишком много попыток'), findsOneWidget);
    expect(container.read(authRepositoryProvider).isLoggedIn, isFalse);
  });

  testWidgets('старый 6-значный PIN: стирание после промаха считается попыткой',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    _mockPins(admin: '123456', staff: '5678');
    final container = await _pumpPinScreen(tester);

    for (var i = 0; i < 5; i++) {
      await _type(tester, '999$i<');
    }

    expect(container.read(authRepositoryProvider.notifier).lockoutSecondsRemaining,
        greaterThan(0));
  });

  testWidgets('верный короткий PIN открывает сразу, без лишней ошибки',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    _mockPins(admin: '123456', staff: '5678');
    final container = await _pumpPinScreen(tester);

    await _type(tester, '5678');

    final auth = container.read(authRepositoryProvider);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.role, UserRole.staff);
    expect(container.read(authRepositoryProvider.notifier).attemptsRemaining, 5);
  });
}
