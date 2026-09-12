import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/analytics/presentation/analytics_screen.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/history/presentation/history_screen.dart';
import 'package:horeca_app/features/home/presentation/home_screen.dart';
import 'package:horeca_app/features/iiko/presentation/iiko_screen.dart';
import 'package:horeca_app/features/inventory/presentation/inventory_screen.dart';
import 'package:horeca_app/features/request/presentation/request_screen.dart';
import 'package:horeca_app/features/settings/presentation/settings_screen.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_screen.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('заставка уходит и открывается главный экран', (tester) async {
    final prefs = await freshPrefs();
    await pumpApp(tester, prefs);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  group('кнопки главного экрана ведут на свои экраны', () {
    final targets = <String, Type>{
      'Сделать заявку': RequestScreen,
      'Закрытие смены': ShiftCloseScreen,
      'Инвентаризация': InventoryScreen,
      'Аналитика и инсайты': AnalyticsScreen,
      'iiko': IikoScreen,
    };

    for (final entry in targets.entries) {
      testWidgets('«${entry.key}»', (tester) async {
        final prefs = await freshPrefs();
        await pumpApp(tester, prefs);

        await tester.ensureVisible(find.text(entry.key));
        await tapText(tester, entry.key);
        expect(find.byType(entry.value), findsOneWidget,
            reason: 'кнопка «${entry.key}» должна открывать ${entry.value}');
      });
    }
  });

  testWidgets('нижняя навигация переключает разделы', (tester) async {
    final prefs = await freshPrefs();
    await pumpApp(tester, prefs);

    await tapText(tester, 'История');
    expect(find.byType(HistoryScreen), findsOneWidget);

    await tapText(tester, 'Настройки');
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tapText(tester, 'Akyl');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('сотруднику не видны настройки и аналитика', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);

    final auth = container.read(authRepositoryProvider.notifier);
    auth.setAdminPin('1111');
    auth.setStaffPin('2222');
    auth.setPinsEnabled(true);
    auth.login(UserRole.staff);
    await settle(tester);

    expect(find.text('Настройки'), findsNothing);
    expect(find.text('Аналитика и инсайты'), findsNothing);
    // Рабочие функции остаются доступны.
    expect(find.text('Сделать заявку'), findsOneWidget);
  });

  testWidgets('кнопка блокировки возвращает экран PIN-кода', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);

    final auth = container.read(authRepositoryProvider.notifier);
    auth.setAdminPin('1111');
    auth.setStaffPin('2222');
    auth.setPinsEnabled(true);
    auth.login(UserRole.admin);
    await settle(tester);

    await tester.tap(find.byIcon(Icons.lock_outline_rounded));
    await settle(tester);

    expect(find.text('Введите PIN-код'), findsOneWidget);

    // И PIN-код действительно открывает приложение обратно.
    for (final d in ['1', '1', '1', '1']) {
      await tester.tap(find.text(d).first);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('сотрудника выкидывает из настроек при смене роли',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);

    await tapText(tester, 'Настройки');
    expect(find.byType(SettingsScreen), findsOneWidget);

    final auth = container.read(authRepositoryProvider.notifier);
    auth.setAdminPin('1111');
    auth.setStaffPin('2222');
    auth.setPinsEnabled(true);
    auth.login(UserRole.staff);
    await settle(tester);

    expect(find.byType(SettingsScreen), findsNothing,
        reason: 'админский раздел закрыт и на уровне маршрутизации');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('заявка возвращает назад по шагам, а не в никуда',
      (tester) async {
    final prefs = await freshPrefs();
    await pumpApp(tester, prefs);

    await tapText(tester, 'Сделать заявку');
    await tapText(tester, 'Кухня');
    expect(find.text('Продукты'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle(tester);
    expect(find.text('Кухня'), findsWidgets, reason: 'вернулись к отделам');
  });
}
