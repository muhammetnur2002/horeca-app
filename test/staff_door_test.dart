import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/staff_shell.dart';

// Дверь сотрудника по макету: профиль первым, четыре вкладки, сфера по
// специальности, пустые состояния без выдуманных вакансий.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('сфера считается по специальности', () {
    expect(workSphereLabel(HospitalityRole.cook), 'кухня');
    expect(workSphereLabel(HospitalityRole.bartender), 'бар');
    expect(workSphereLabel(HospitalityRole.barista), 'бар');
    expect(workSphereLabel(HospitalityRole.waiter), 'зал');
    expect(workSphereLabel(HospitalityRole.manager), 'управление');
  });

  Future<SharedPreferences> prefsWithProfile({bool create = true}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (create) {
      final people = PeopleRepository(prefs);
      people.createProfile('Аня Ковалёва', random: Random(3));
      people.addWorkplace(
        venueName: 'Дом у реки',
        role: HospitalityRole.cook,
        startedAt: DateTime(2026, 6, 3),
        endedAt: DateTime(2026, 9, 30),
      );
    }
    return prefs;
  }

  Future<void> pumpShell(WidgetTester tester, SharedPreferences prefs) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: StaffShell()),
    ));
    await tester.pump();
  }

  testWidgets('без профиля — сначала создать профиль, без вкладок', (tester) async {
    await pumpShell(tester, await prefsWithProfile(create: false));
    expect(find.text('Личный профиль'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('профиль открыт первым, вкладки по макету', (tester) async {
    await pumpShell(tester, await prefsWithProfile());
    expect(find.text('Профиль сотрудника'), findsOneWidget);
    expect(find.text('Аня Ковалёва'), findsOneWidget);
    expect(find.text('Фотоальбом'), findsOneWidget);
    for (final label in ['Главная', 'Смены', 'Профиль', 'Уведомления']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Главная'));
    await tester.pump();
    expect(find.text('Мои чаты'), findsOneWidget);
    expect(find.text('Ваша сфера: кухня.'), findsOneWidget);
    expect(find.text('Вакансий вашей сферы пока нет'), findsOneWidget);
    expect(find.text('Откликов пока нет'), findsOneWidget);

    await tester.tap(find.text('Смены'));
    await tester.pump();
    expect(find.text('Смены и стаж'), findsOneWidget);
    expect(find.text('Дом у реки'), findsWidgets);

    await tester.tap(find.text('Уведомления'));
    await tester.pump();
    expect(find.text('Уведомлений нет'), findsOneWidget);
  });
}
