import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/legacy_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Проверки переноса из SharedPreferences в базу.
///
/// Перенос выполняется один раз на устройстве и его нельзя переиграть
/// у пользователя. Поэтому здесь проверяется не только удачный случай,
/// но и всё, что можно найти в реальных данных: чужие типы, пустые
/// строки, ссылки в никуда, испорченный JSON.
void main() {
  late AppDatabase db;
  late CatalogDao catalog;
  late OperationsDao operations;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogDao(db);
    operations = OperationsDao(db);
  });

  tearDown(() => db.close());

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  const settings = {
    'establishmentName': 'Кофейня на углу',
    'currency': '₸',
    'departments': [
      {'id': '1', 'name': 'Бар', 'icon': 'local_bar'},
      {'id': '2', 'name': 'Кухня', 'icon': 58136},
    ],
    'categories': [
      {'id': '10', 'name': 'Напитки', 'departmentId': '1'},
      {'id': '11', 'name': 'Ничьё', 'departmentId': '999'},
    ],
    'products': [
      {'id': '100', 'name': 'Кофе', 'unit': 'кг', 'categoryId': '10'},
      {'id': '101', 'name': 'Молоко', 'unit': 'л', 'minStock': 5},
      {'id': '102', 'name': '   '},
    ],
    'staff': ['Айгуль', '', 'Данияр'],
  };

  test('справочник переносится, ссылки переписываются на новые id', () async {
    final prefs = await prefsWith({'settings_data': jsonEncode(settings)});
    final report = await LegacyMigration.run(db: db, prefs: prefs);

    expect(report.skipped, isFalse);
    expect(report.failures, isEmpty);
    expect(report.departments, 2);
    expect(report.categories, 2);
    // Товар с пустым названием пропущен.
    expect(report.products, 2);
    // Пустая строка сотрудником не считается.
    expect(report.staff, 2);

    final establishment = report.establishmentId!;
    final departments = await catalog.loadDepartments(establishment);
    final categories = await catalog.loadCategories(establishment);
    final products = await catalog.loadProducts(establishment);

    // Старые id были порядковыми номерами устройства. После переноса
    // их не должно остаться нигде: два телефона дали бы одинаковые
    // номера разным товарам.
    expect(departments.map((d) => d.id), isNot(contains('1')));

    final bar = departments.firstWhere((d) => d.name == 'Бар');
    final drinks = categories.firstWhere((c) => c.name == 'Напитки');
    expect(drinks.departmentId, bar.id);

    // Ссылка в несуществующий отдел превращается в пустую, а не
    // в битую: строка сохраняется, связь теряется.
    expect(categories.firstWhere((c) => c.name == 'Ничьё').departmentId,
        isNull);

    expect(products.firstWhere((p) => p.name == 'Кофе').categoryId, drinks.id);
    expect(products.firstWhere((p) => p.name == 'Молоко').minStock, 5);
  });

  test('числовой codePoint не становится ключом иконки', () async {
    final prefs = await prefsWith({'settings_data': jsonEncode(settings)});
    final report = await LegacyMigration.run(db: db, prefs: prefs);

    final kitchen = (await catalog.loadDepartments(report.establishmentId!))
        .firstWhere((d) => d.name == 'Кухня');
    expect(kitchen.iconKey, 'category');
  });

  test('суммы смен переводятся в целые минорные единицы', () async {
    final prefs = await prefsWith({
      'settings_data': jsonEncode(settings),
      'shift_records': jsonEncode([
        {
          'date': '2026-03-01T22:00:00Z',
          'revenue': 150000.55,
          'card': 100000,
          'cash': 50000.55,
          'writeOffs': {'Молоко': 2.5, 'Сироп': 0},
        }
      ]),
    });

    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.shifts, 1);
    expect(report.writeoffs, 1);

    final shift =
        (await operations.loadShifts(report.establishmentId!)).single;
    expect(shift.revenueMinor, 15000055);
    expect(shift.cardMinor, 10000000);
    expect(shift.cashMinor, 5000055);
  });

  test('отрицательная сумма не роняет перенос', () async {
    final prefs = await prefsWith({
      'settings_data': jsonEncode(settings),
      'shift_records': jsonEncode([
        {'date': '2026-03-01T22:00:00Z', 'revenue': -500}
      ]),
    });

    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.failures, isEmpty);
    expect(report.shifts, 1);
    expect(
      (await operations.loadShifts(report.establishmentId!)).single.revenueMinor,
      0,
    );
  });

  test('остатки привязываются к новым id, потерянные отбрасываются', () async {
    final prefs = await prefsWith({
      'settings_data': jsonEncode(settings),
      'current_stock_levels': jsonEncode({'100': 12.5, '999': 3.0}),
    });

    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.stockLevels, 1);

    final establishment = report.establishmentId!;
    final coffee = (await catalog.loadProducts(establishment))
        .firstWhere((p) => p.name == 'Кофе');
    expect(await operations.loadStockLevels(establishment), {coffee.id: 12.5});
  });

  test('испорченный JSON не отменяет остальные разделы', () async {
    final prefs = await prefsWith({
      'settings_data': jsonEncode(settings),
      'history_data': '{это не json',
    });

    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.hasFailures, isTrue);
    expect(report.failures.single, contains('история'));
    // Справочник при этом на месте.
    expect(report.products, 2);
  });

  test('перенос выполняется один раз', () async {
    final prefs = await prefsWith({'settings_data': jsonEncode(settings)});

    final first = await LegacyMigration.run(db: db, prefs: prefs);
    expect(first.skipped, isFalse);
    expect(LegacyMigration.isDone(prefs), isTrue);

    final second = await LegacyMigration.run(db: db, prefs: prefs);
    expect(second.skipped, isTrue);
    expect(second.products, 0);
  });

  test('пустые настройки дают пустое, но рабочее заведение', () async {
    final prefs = await prefsWith(<String, Object>{});
    final report = await LegacyMigration.run(db: db, prefs: prefs);

    expect(report.failures, isEmpty);
    expect(report.establishmentId, isNotNull);
    expect(await catalog.loadEstablishment(), isNotNull);
  });

  test('старые ключи остаются на месте', () async {
    final prefs = await prefsWith({'settings_data': jsonEncode(settings)});
    await LegacyMigration.run(db: db, prefs: prefs);

    // Данные не удаляются: если перенос окажется неполным,
    // разобрать исходник можно будет вручную.
    expect(prefs.getString('settings_data'), isNotNull);
  });
}
