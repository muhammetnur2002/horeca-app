import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openShiftClose(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Закрытие смены'));
    await tapText(tester, 'Закрытие смены');
  }

  /// В демо-данных есть категория «Десерты», поэтому переход с шага 1
  /// спрашивает подтверждение нулевых остатков.
  Future<void> goToPayments(WidgetTester tester) async {
    await tapText(tester, 'Далее');
    if (find.text('Десертов не осталось?').evaluate().isNotEmpty) {
      await tapText(tester, 'Продолжить');
    }
  }

  testWidgets('шаг «Далее» требует выбрать сотрудника', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openShiftClose(tester);

    await tapText(tester, 'Далее');
    expect(find.text('Отметьте хотя бы одного сотрудника'), findsOneWidget);
    expect(find.text('Десертов не осталось?'), findsNothing);
    expect(find.text('Шаг 1 из 4'), findsOneWidget, reason: 'остались на шаге 1');
  });

  testWidgets('шаг оплаты требует заполнить суммы', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openShiftClose(tester);

    await tapText(tester, 'Настя');
    await goToPayments(tester);
    expect(find.text('Шаг 2 из 4'), findsOneWidget);

    await tapText(tester, 'Далее');
    expect(find.textContaining('Укажите сумму по QR-коду'), findsOneWidget);
  });

  testWidgets('полный путь до итога и подсчёт выручки', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openShiftClose(tester);

    await tapText(tester, 'Настя');
    await goToPayments(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1000'); // QR
    await tester.enterText(fields.at(1), '2000'); // карта
    await tester.enterText(fields.at(2), '500');  // наличные
    await settle(tester);
    expect(find.text('3 500 ₸'), findsOneWidget, reason: 'сумма считается на лету');

    await tapText(tester, 'Далее');
    expect(find.text('Шаг 3 из 4'), findsOneWidget);

    final cashFields = find.byType(TextField);
    await tester.enterText(cashFields.at(0), '5000');
    await tester.enterText(cashFields.at(1), '7000');
    await settle(tester);
    await tapText(tester, 'Далее');

    expect(find.text('Шаг 4 из 4'), findsOneWidget);
    expect(find.text('Закрыть смену'), findsOneWidget);
    expect(find.textContaining('Сформировать PDF'), findsOneWidget);
  });

  testWidgets('касса на завтра пересчитывается с инкассацией',
      (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openShiftClose(tester);
    await tapText(tester, 'Настя');
    await goToPayments(tester);

    final pay = find.byType(TextField);
    await tester.enterText(pay.at(0), '0');
    await tester.enterText(pay.at(1), '0');
    await tester.enterText(pay.at(2), '10000');
    await settle(tester);
    await tapText(tester, 'Далее');

    final cash = find.byType(TextField);
    await tester.enterText(cash.at(0), '1000');
    await tester.enterText(cash.at(1), '9000');
    await settle(tester);
    expect(find.text('9 000 ₸'), findsWidgets);

    await tester.tap(find.byType(Switch));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, '4000');
    await settle(tester);
    expect(find.text('5 000 ₸'), findsWidgets,
        reason: '9000 − 4000 инкассации');
  });

  testWidgets('ручное списание добавляется и удаляется', (tester) async {
    await pumpApp(tester, await freshPrefs());
    await openShiftClose(tester);

    await tapText(tester, 'Добавить'); // кнопка секции «Ручные списания»
    expect(find.text('Ручное списание'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Бисквит');
    // В диалоге «Добавить» — последний в дереве.
    await tapWidget(tester, find.widgetWithText(ElevatedButton, 'Добавить'));
    expect(find.text('Бисквит'), findsOneWidget);

    await tapWidget(tester, find.byIcon(Icons.close_rounded).last);
    expect(find.text('Бисквит'), findsNothing);
  });

  testWidgets('отмена подтверждения не записывает смену в аналитику',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    await openShiftClose(tester);

    await tapText(tester, 'Настя');
    await goToPayments(tester);
    final pay = find.byType(TextField);
    await tester.enterText(pay.at(0), '100');
    await tester.enterText(pay.at(1), '0');
    await tester.enterText(pay.at(2), '0');
    await settle(tester);
    await tapText(tester, 'Далее');
    final cash = find.byType(TextField);
    await tester.enterText(cash.at(0), '10');
    await tester.enterText(cash.at(1), '20');
    await settle(tester);
    await tapText(tester, 'Далее');

    await tapText(tester, 'Закрыть смену');
    expect(find.text('Закрыть смену?'), findsOneWidget);
    await tapText(tester, 'Отмена');

    expect(container.read(analyticsRepositoryProvider).getAll(), isEmpty);
  });

  testWidgets('без сотрудников подсказывает, где их добавить',
      (tester) async {
    final prefs = await freshPrefs();
    final container = await pumpApp(tester, prefs);
    container.read(settingsRepositoryProvider.notifier).resetAll();
    await settle(tester);

    await openShiftClose(tester);
    expect(find.textContaining('Добавьте сотрудников'), findsOneWidget);
  });
}

