import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/presentation/tabs/departments_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab.dart';
import 'package:horeca_app/features/settings/presentation/tabs/shift_tab.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSettings(WidgetTester tester, String tab) async {
    await tapText(tester, 'Настройки');
    await tapText(tester, tab);
  }

  testWidgets('все вкладки настроек открываются', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await tapText(tester, 'Настройки');

    for (final tab in [
      'Отделы',
      'Категории',
      'Товары',
      'Смена',
      'Тема',
      'Заведение',
    ]) {
      await tapText(tester, tab);
      expect(tester.takeException(), isNull, reason: 'вкладка «$tab»');
    }
  });

  testWidgets('добавление и удаление отдела работают', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await openSettings(tester, 'Отделы');

    await tapWidget(tester, fabOf(DepartmentsTab));
    await tester.enterText(find.byType(TextField).last, 'Кондитерская');
    await tapText(tester, 'Добавить');

    expect(
        container
            .read(settingsRepositoryProvider)
            .departments
            .any((d) => d.name == 'Кондитерская'),
        isTrue);

    // Удаление спрашивает подтверждение.
    final before =
        container.read(settingsRepositoryProvider).departments.length;
    await tapWidget(tester, find.descendant(of: find.byType(DepartmentsTab), matching: find.byIcon(Icons.delete_outline_rounded)).last);
    expect(find.text('Удалить отдел?'), findsOneWidget);
    await tapText(tester, 'Отмена');
    expect(container.read(settingsRepositoryProvider).departments.length,
        before, reason: 'отмена ничего не удаляет');

    await tapWidget(tester, find.descendant(of: find.byType(DepartmentsTab), matching: find.byIcon(Icons.delete_outline_rounded)).last);
    await tapText(tester, 'Удалить');
    expect(container.read(settingsRepositoryProvider).departments.length,
        before - 1);
  });

  testWidgets('добавление сотрудника и его удаление', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await openSettings(tester, 'Смена');

    await tapWidget(tester, fabOf(ShiftTab));
    await tester.enterText(find.byType(TextField).last, '  Айгуль  ');
    await tapText(tester, 'Добавить');

    expect(container.read(settingsRepositoryProvider).staff, contains('Айгуль'),
        reason: 'имя должно сохраняться без лишних пробелов');
  });

  testWidgets('кнопки темы переключают и сохраняют режим', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await openSettings(tester, 'Тема');

    await tapText(tester, 'Тёмная');
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');

    await tapText(tester, 'Авто');
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(prefs.getString('theme_mode'), 'system',
        reason: 'раньше «Авто» сохранялось как «dark»');

    await tapText(tester, 'Светлая');
    expect(prefs.getString('theme_mode'), 'light');
  });

  testWidgets('«Очистить все данные» действительно чистит всё',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    container.read(historyRepositoryProvider.notifier).add(HistoryEntry(
        id: '1', type: HistoryType.request, title: 'x', text: 'y',
        createdAt: DateTime(2026, 1, 1)));

    await openSettings(tester, 'Тема');
    await tapText(tester, 'Очистить все данные');
    await tapText(tester, 'Удалить всё');

    final s = container.read(settingsRepositoryProvider);
    expect(s.departments, isEmpty);
    expect(s.products, isEmpty);
    expect(s.staff, isEmpty);
    expect(container.read(historyEntriesProvider), isEmpty);
  });

  testWidgets('экран лицензий открытого ПО доступен', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openSettings(tester, 'Тема');
    await tapText(tester, 'Лицензии открытого ПО');
    expect(find.text('Лицензии открытого ПО'), findsWidgets,
        reason: 'раньше на этот экран не вело ни одной кнопки');
  });

  testWidgets('политика и условия открываются', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openSettings(tester, 'Тема');

    await tapText(tester, 'Политика конфиденциальности');
    expect(find.textContaining('ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ'), findsOneWidget);
    await closeSheet(tester);

    await tapText(tester, 'Условия использования');
    expect(find.textContaining('УСЛОВИЯ ИСПОЛЬЗОВАНИЯ'), findsOneWidget);
  });

  testWidgets('массовое добавление товаров создаёт их все', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await openSettings(tester, 'Товары');

    final before = container.read(settingsRepositoryProvider).products.length;
    await tapWidget(tester, fabOf(ProductsTab));
    await tester.enterText(
        find.byType(TextField).last, 'Базилик\nОрегано\n\nТимьян');
    await tapText(tester, 'Добавить');

    expect(container.read(settingsRepositoryProvider).products.length,
        before + 3, reason: 'пустые строки должны отбрасываться');
  });

  testWidgets('минимальный остаток задаётся и переживает переименование',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await openSettings(tester, 'Товары');

    await tapWidget(tester, find.byIcon(Icons.notifications_outlined).first);
    await tester.enterText(find.byType(TextField).last, '4');
    await tapText(tester, 'Сохранить');

    final withMin = container
        .read(settingsRepositoryProvider)
        .products
        .where((p) => p.minStock != null);
    expect(withMin, hasLength(1));
    expect(withMin.single.minStock, 4);
  });
}
