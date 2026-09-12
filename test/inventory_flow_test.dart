import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/inventory/presentation/inventory_screen.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openInventory(WidgetTester tester) async {
    await pumpApp(tester, await freshPrefs());
    await tester.ensureVisible(find.text('Инвентаризация'));
    await tapText(tester, 'Инвентаризация');
    expect(find.byType(InventoryScreen), findsOneWidget);
  }

  testWidgets('кнопки «+» и «−» действительно меняют остаток', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await tester.ensureVisible(find.text('Инвентаризация'));
    await tapText(tester, 'Инвентаризация');

    await tapText(tester, 'Кухня');
    await tapText(tester, 'Далее');

    // Первый «+» в списке товаров.
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);

    final state = container.read(inventoryStateProvider);
    expect(state.items, isNotEmpty,
        reason: 'нажатие «+» должно создавать позицию инвентаризации');
    expect(state.items.first.remaining, 2);

    await tester.tap(find.byIcon(Icons.remove).first);
    await settle(tester);
    expect(container.read(inventoryStateProvider).items.first.remaining, 1);
  });

  testWidgets('ручной ввод остатка принимает дробное значение',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await tester.ensureVisible(find.text('Инвентаризация'));
    await tapText(tester, 'Инвентаризация');
    await tapText(tester, 'Кухня');
    await tapText(tester, 'Далее');

    // Тап по числу открывает диалог ручного ввода.
    await tester.tap(find.text('0').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '2,5');
    await tapText(tester, 'OK');

    expect(container.read(inventoryStateProvider).items.first.remaining, 2.5);
  });

  testWidgets('есть кнопка перехода к отчёту, и она его формирует',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await tester.ensureVisible(find.text('Инвентаризация'));
    await tapText(tester, 'Инвентаризация');
    await tapText(tester, 'Кухня');
    await tapText(tester, 'Далее');

    expect(find.textContaining('Сформировать отчёт'), findsOneWidget,
        reason: 'без этой кнопки шаг ввода остатков был тупиком');

    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tester.tap(find.textContaining('Сформировать отчёт'));
    await settle(tester);

    expect(container.read(inventoryStateProvider).step, 3);
    expect(find.text('Шаг 4'), findsOneWidget);
    // В отчёте есть реальный товар, а не пустая заготовка.
    expect(find.textContaining('Томаты'), findsWidgets);
  });

  testWidgets('пустой отчёт не формируется', (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await tester.ensureVisible(find.text('Инвентаризация'));
    await tapText(tester, 'Инвентаризация');
    await tapText(tester, 'Кухня');
    await tapText(tester, 'Далее');

    await tester.tap(find.textContaining('Сформировать отчёт'));
    await settle(tester);

    expect(container.read(inventoryStateProvider).step, 2);
    expect(find.textContaining('Введите остаток'), findsOneWidget);
  });

  testWidgets('в отчёте стоит название отдела, а не его id', (tester) async {
    final prefs = await freshPrefs();
    await pumpApp(tester, prefs);
    await tester.ensureVisible(find.text('Инвентаризация'));
    await tapText(tester, 'Инвентаризация');
    await tapText(tester, 'Бар');
    await tapText(tester, 'Далее');
    await tester.tap(find.byIcon(Icons.add).first);
    await settle(tester);
    await tester.tap(find.textContaining('Сформировать отчёт'));
    await settle(tester);

    expect(find.textContaining('Отдел: Бар'), findsOneWidget);
    expect(find.textContaining('Отдел: 2'), findsNothing);
  });

  testWidgets('«Назад» со списка товаров ведёт к выбору категорий',
      (tester) async {
    await openInventory(tester);
    await tapText(tester, 'Кухня');
    await tapText(tester, 'Далее');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle(tester);

    expect(find.text('Выберите категории'), findsOneWidget,
        reason: 'раньше кнопка сбрасывала весь процесс к выбору отдела');
  });

  testWidgets('снятие категории убирает её товары из списка', (tester) async {
    await openInventory(tester);
    await tapText(tester, 'Кухня');

    // Снимаем «Продукты» — «Томаты» и «Сыр» должны исчезнуть.
    await tapText(tester, 'Продукты');
    await tapText(tester, 'Далее');

    expect(find.text('Томаты'), findsNothing);
    expect(find.text('Замороженные овощи'), findsOneWidget);
  });
}
