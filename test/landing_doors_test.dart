import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/landing/data/door_repository.dart';
import 'package:horeca_app/features/landing/presentation/landing_screen.dart';

// Лендинг с двумя дверями: новый человек выбирает дверь, живой пользователь
// заведения лендинг не видит, выбор запоминается и сбрасывается.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('новый телефон видит лендинг', () async {
    expect(initialDoor(await prefsWith({})), isNull);
  });

  test('гость без PIN и облака тоже видит лендинг', () async {
    final prefs = await prefsWith({'account_gate_skipped': true, 'settings_data': '{}'});
    expect(initialDoor(prefs), isNull);
  });

  test('кто входил в облако или включал PIN — сразу в заведение', () async {
    expect(initialDoor(await prefsWith({'account_ever_logged_in': true})), AppDoor.venue);
    expect(initialDoor(await prefsWith({'pins_enabled': true})), AppDoor.venue);
    expect(initialDoor(await prefsWith({'pins_enabled_02': true})), AppDoor.venue);
    expect(initialDoor(await prefsWith({'pins_enabled': false})), isNull);
  });

  test('выбор запоминается, «Сменить вход» снова показывает лендинг', () async {
    final prefs = await prefsWith({'pins_enabled': true});
    final door = DoorNotifier(prefs);
    door.choose(AppDoor.staff);
    expect(DoorNotifier(prefs).state, AppDoor.staff);
    door.reset();
    expect(door.state, isNull);
    expect(prefs.getString(doorPrefsKey), isNull);
  });

  testWidgets('кнопки лендинга открывают свою дверь', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final prefs = await prefsWith({});
    final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LandingScreen()),
    ));
    expect(find.text('Akyl'), findsOneWidget);
    expect(find.text('Работа и заведение\nв одном месте'), findsOneWidget);

    await tester.tap(find.text('Я сотрудник'));
    expect(container.read(doorProvider), AppDoor.staff);

    await tester.tap(find.text('Я владелец заведения'));
    expect(container.read(doorProvider), AppDoor.venue);
    expect(prefs.getString(doorPrefsKey), 'venue');
  });
}
