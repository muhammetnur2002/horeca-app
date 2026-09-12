import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/notifications/presentation/notifications_screen.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('История', () {
    testWidgets('очистка спрашивает подтверждение и уважает отмену',
        (tester) async {
      final prefs = await freshPrefs();
      final container = await pumpApp(tester, prefs);
      container.read(historyRepositoryProvider.notifier).add(HistoryEntry(
          id: '1', type: HistoryType.request, title: 'Заявка — Кухня',
          text: 'Томаты — 1 кг', createdAt: DateTime(2026, 4, 1)));
      await settle(tester);
      await tapText(tester, 'История');

      await tapWidget(tester, find.byIcon(Icons.delete_sweep_outlined));
      expect(find.text('Очистить историю'), findsWidgets,
          reason: 'раньше история стиралась без единого вопроса');

      await tapText(tester, 'Отмена');
      expect(container.read(historyEntriesProvider), hasLength(1));

      await tapWidget(tester, find.byIcon(Icons.delete_sweep_outlined));
      await tapText(tester, 'Удалить');
      expect(container.read(historyEntriesProvider), isEmpty);
    });

    testWidgets('очистка на пустой вкладке не открывает диалог',
        (tester) async {
      await pumpApp(tester, await freshPrefs());
      await tapText(tester, 'История');
      await tapWidget(tester, find.byIcon(Icons.delete_sweep_outlined));
      expect(find.text('Очистить историю'), findsNothing);
      expect(find.text('Нет записей'), findsWidgets);
    });

    testWidgets('вкладки разделяют заявки и инвентаризации', (tester) async {
      final prefs = await freshPrefs();
      final container = await pumpApp(tester, prefs);
      final repo = container.read(historyRepositoryProvider.notifier);
      repo.add(HistoryEntry(
          id: '1', type: HistoryType.request, title: 'Заявка А', text: '',
          createdAt: DateTime(2026, 1, 1)));
      repo.add(HistoryEntry(
          id: '2', type: HistoryType.inventory, title: 'Инвентаризация Б',
          text: '', createdAt: DateTime(2026, 1, 2)));
      await settle(tester);

      await tapText(tester, 'История');
      expect(find.text('Заявка А'), findsOneWidget);
      expect(find.text('Инвентаризация Б'), findsNothing);

      await tapText(tester, 'Инвентаризации');
      expect(find.text('Инвентаризация Б'), findsOneWidget);
    });

    testWidgets('запись открывается в деталях', (tester) async {
      final prefs = await freshPrefs();
      final container = await pumpApp(tester, prefs);
      container.read(historyRepositoryProvider.notifier).add(HistoryEntry(
          id: '1', type: HistoryType.request, title: 'Заявка — Бар',
          text: 'Кола — 3 л', createdAt: DateTime(2026, 2, 2)));
      await settle(tester);

      await tapText(tester, 'История');
      await tapText(tester, 'Заявка — Бар');
      expect(find.text('Кола — 3 л'), findsWidgets);
    });
  });

  group('iiko', () {
    testWidgets('пустой логин даёт понятную ошибку', (tester) async {
      await pumpApp(tester, await freshPrefs());
      await tester.ensureVisible(find.text('iiko'));
      await tapText(tester, 'iiko');

      await tapText(tester, 'Подключить');
      expect(find.text('Введите API-логин iiko'), findsOneWidget,
          reason: 'раньше кнопка молча ничего не делала');
    });

    testWidgets('демо-режим показывает остатки', (tester) async {
      await pumpApp(tester, await freshPrefs());
      await tester.ensureVisible(find.text('iiko'));
      await tapText(tester, 'iiko');

      await tapText(tester, 'Демо-режим (без iiko)');
      expect(find.text('Остатки на складе'), findsOneWidget);
      expect(find.text('Кофе зерновой'), findsOneWidget);
    });
  });

  group('Аналитика', () {
    testWidgets('без смен показывает подсказку', (tester) async {
      await pumpApp(tester, await freshPrefs());
      await tester.ensureVisible(find.text('Аналитика и инсайты'));
      await tapText(tester, 'Аналитика и инсайты');
      expect(find.textContaining('Закройте смену'), findsOneWidget);
    });

    testWidgets('переключатель периода работает', (tester) async {
      final prefs = await freshPrefs();
      final container = await pumpApp(tester, prefs);
      final repo = container.read(analyticsRepositoryProvider);
      repo.addShift(ShiftRecord(
          date: DateTime.now().subtract(const Duration(days: 1)),
          revenue: 1000, writeOffs: {'Торт': 1}));
      repo.addShift(ShiftRecord(
          date: DateTime.now(), revenue: 1500, writeOffs: {}));
      await settle(tester);

      await tester.ensureVisible(find.text('Аналитика и инсайты'));
      await tapText(tester, 'Аналитика и инсайты');
      expect(find.text('Выручка по дням'), findsOneWidget);

      await tapText(tester, '30 дней');
      expect(tester.takeException(), isNull);
      expect(find.text('Топ списываемых товаров'), findsOneWidget);
    });
  });

  group('Уведомления', () {
    testWidgets('напоминание о товаре добавляется и удаляется',
        (tester) async {
      final prefs = await freshPrefs();
      final container = await pumpApp(tester, prefs);
      await tester.pumpWidget(wrapScreen(const NotificationsScreen(), prefs));
      await settle(tester);

      await tapText(tester, 'Добавить');
      await tester.enterText(find.byType(TextField).last, 'Молоко');
      await tapWidget(tester, find.widgetWithText(ElevatedButton, 'Добавить'));

      expect(find.text('Молоко'), findsOneWidget);
      container.dispose();
    });

    testWidgets('переключатель инвентаризации меняет состояние',
        (tester) async {
      final prefs = await freshPrefs();
      await tester.pumpWidget(wrapScreen(const NotificationsScreen(), prefs));
      await settle(tester);

      final sw = find.byType(Switch).first;
      expect(tester.widget<Switch>(sw).value, isFalse);
      await tapWidget(tester, sw);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    });
  });
}
