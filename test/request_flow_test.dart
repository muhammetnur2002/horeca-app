import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openProducts(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Сделать заявку'));
    await tapText(tester, 'Сделать заявку');
    await tapText(tester, 'Кухня');
    await tapText(tester, 'Продукты');
  }

  testWidgets('«+», «−» и ручной ввод меняют количество', (tester) async {
    final container = await pumpApp(tester, await freshPrefs());
    await openProducts(tester);

    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    expect(container.read(requestStateProvider).items.single.quantity, 1);

    await tester.tap(find.byIcon(Icons.remove).first);
    await settle(tester);
    expect(container.read(requestStateProvider).items, isEmpty,
        reason: 'нулевое количество убирает позицию из заявки');
  });

  testWidgets('в заявке можно указать дробное количество', (tester) async {
    final container = await pumpApp(tester, await freshPrefs());
    await openProducts(tester);

    await tester.tap(find.text('0').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '0.5');
    await tapText(tester, 'OK');

    expect(container.read(requestStateProvider).items.single.quantity, 0.5,
        reason: 'раньше поле принимало только целые');
  });

  testWidgets('предпросмотр пустой заявки предупреждает, а не открывается',
      (tester) async {
    final container = await pumpApp(tester, await freshPrefs());
    await openProducts(tester);

    await tapText(tester, 'Предпросмотр');
    expect(container.read(requestStateProvider).step, 2);
    expect(find.textContaining('Добавьте хотя бы один товар'), findsOneWidget);
  });

  testWidgets('полный путь заявки: товар → предпросмотр → текст',
      (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openProducts(tester);

    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tapText(tester, 'Предпросмотр (1)');

    expect(find.textContaining('Отдел: Кухня'), findsOneWidget);
    expect(find.textContaining('Томаты'), findsWidgets);
    expect(find.textContaining('Спасибо!'), findsOneWidget);
  });

  testWidgets('кнопка «Скопировать» кладёт текст в буфер', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpApp(tester, await freshPrefs());
    await openProducts(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tapText(tester, 'Предпросмотр (1)');
    await tapText(tester, 'Скопировать');

    expect(copied, isNotNull);
    expect(copied, contains('Томаты'));
    expect(find.text('Текст скопирован в буфер обмена'), findsOneWidget);
  });

  testWidgets('«Новая заявка» сбрасывает состояние и уводит домой',
      (tester) async {
    final container = await pumpApp(tester, await freshPrefs());
    await openProducts(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tapText(tester, 'Предпросмотр (1)');
    await tapText(tester, 'Новая заявка');

    final s = container.read(requestStateProvider);
    expect(s.step, 0);
    expect(s.items, isEmpty);
    expect(s.departmentId, isNull);
  });

  testWidgets('«Редактировать» возвращает к списку товаров', (tester) async {
    final container = await pumpApp(tester, await freshPrefs());
    await openProducts(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tapText(tester, 'Предпросмотр (1)');
    await tapText(tester, 'Редактировать');
    expect(container.read(requestStateProvider).step, 2);
  });

  testWidgets('поиск фильтрует товары и очищается крестиком', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openProducts(tester);

    await tester.enterText(find.byType(TextField).first, 'сыр');
    await settle(tester);
    expect(find.text('Сыр'), findsOneWidget);
    expect(find.text('Томаты'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await settle(tester);
    expect(find.text('Томаты'), findsOneWidget);
  });

  testWidgets('история пополняется и сразу видна на экране истории',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);

    // Пишем запись напрямую: сохранение PDF требует платформенных каналов.
    container.read(historyRepositoryProvider.notifier).add(HistoryEntry(
          id: '1',
          type: HistoryType.request,
          title: 'Заявка — Кухня',
          text: 'Томаты — 1 кг',
          createdAt: DateTime(2026, 4, 1),
        ));
    await settle(tester);

    await tapText(tester, 'История');
    expect(find.text('Заявка — Кухня'), findsOneWidget,
        reason: 'раньше список кэшировался и новые записи не появлялись');
  });
}
