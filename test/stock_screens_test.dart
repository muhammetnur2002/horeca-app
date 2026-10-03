import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/presentation/audit_screen.dart';
import 'package:horeca_app/features/stock/presentation/baseline_screen.dart';
import 'package:horeca_app/features/stock/presentation/receipt_screen.dart';
import 'package:horeca_app/features/stock/presentation/stock_screen.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Дымовые тесты экранов учёта: открываются без ошибок вёрстки
/// и показывают данные из базы.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late String venueId;
  late String productId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final catalog = CatalogDao(db);
    venueId = await catalog.upsertVenue(code: '01', name: 'Центр');
    productId = await catalog.upsertProduct(
        venueId: venueId, name: 'Молоко', unit: 'коробка', inventoryUnit: 'л');
  });
  tearDown(() => db.close());

  Future<void> pumpScreen(WidgetTester tester, Widget screen,
      {bool dark = false}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        initialVenuesProvider.overrideWithValue(
            [Venue(id: venueId, code: '01', name: 'Центр')]),
      ],
      child: MaterialApp(
        theme: buildAppLightTheme(),
        darkTheme: buildAppDarkTheme(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: screen,
      ),
    ));
    // Даём запросам к базе завершиться, затем дорисовываем кадр.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
  }

  testWidgets('Учёт товара: без замеров подсказывает стартовые остатки',
      (tester) async {
    await pumpScreen(tester, const StockScreen());
    expect(find.text('Принять поставку'), findsOneWidget);
    expect(find.textContaining('нужна точка отсчёта'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Учёт товара показывает остаток после приёмки', (tester) async {
    final stock = StockRepository(OperationsDao(db), venueId);
    await tester.runAsync(() async {
      await stock.recordCount({productId: 2}, baseline: true);
      await stock.recordReceipt(
        lines: [
          ReceiptLine(productId: productId, productName: 'Молоко',
              unit: 'коробка', unitFactor: 12, received: 1),
        ],
        title: 'Приёмка без заявки',
        text: 'Пришло: Молоко',
      );
    });
    await pumpScreen(tester, const StockScreen(), dark: true);
    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('14 л'), findsOneWidget);
    expect(find.text('Приход + 12'), findsOneWidget);
    await tester.tap(find.text('Приёмки'));
    await tester.pumpAndSettle();
    expect(find.text('Приёмка без заявки'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Приёмка без заявки: выбор и пустой список', (tester) async {
    await pumpScreen(tester, const ReceiptScreen());
    expect(find.text('Сохранённых заявок пока нет.'), findsOneWidget);
    await tester.tap(find.text('Приёмка без заявки'));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(find.text('Добавить товар не из заявки'), findsOneWidget);
    expect(find.text('Принять поставку'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Стартовые остатки и журнал действий открываются',
      (tester) async {
    await pumpScreen(tester, const BaselineScreen());
    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Сохранить (0)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '3,5');
    await tester.pump();
    expect(find.text('Сохранить (1)'), findsOneWidget);

    await pumpScreen(tester, const AuditScreen());
    expect(find.text('Пока пусто'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Приёмка по заявке: строки подставляются, виден коэффициент',
      (tester) async {
    await tester.runAsync(() => OperationsDao(db).addHistoryEntry(
          venueId: venueId,
          kind: 'request',
          title: 'Заявка: Кухня',
          body: 'x',
          lines: [
            DocumentLineInput(
                productId: productId,
                productName: 'Молоко',
                unit: 'коробка',
                ordered: 2,
                quantity: 2),
          ],
        ));
    await pumpScreen(tester, const ReceiptScreen());
    await tester.tap(find.text('Заявка: Кухня'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    expect(find.text('Заказано: 2 коробка'), findsOneWidget);
    // Заказ в коробках, учёт в литрах — спрашиваем, сколько литров в коробке.
    expect(find.text('1 коробка = '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
