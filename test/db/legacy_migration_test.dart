import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/legacy_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Проверки переноса из SharedPreferences в базу.
///
/// Перенос выполняется на устройстве один раз и переиграть его
/// у пользователя нельзя, поэтому проверяются и реальные «грязные»
/// данные: чужие типы, пустые строки, ссылки в никуда, испорченный JSON.
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

  // Формат, который пишет текущий SettingsRepository (иконка — codePoint
  // строкой, id — '1', '2' или метка времени).
  final venue01Settings = {
    'establishmentName': 'Спартак',
    'currency': '₸',
    'showShiftDesserts': false,
    'departments': [
      {'id': '1', 'name': 'Бар', 'icon': Icons.local_bar.codePoint.toString()},
      {'id': '2', 'name': 'Кухня', 'icon': '999999'},
    ],
    'categories': [
      {'id': '10', 'name': 'Напитки', 'departmentId': '1'},
      {'id': '11', 'name': 'Десерты', 'departmentId': '1'},
      {
        'id': '12',
        'name': 'Сладкое',
        'departmentId': '1',
        'isDessertCategory': true
      },
      {'id': '13', 'name': 'Ничьё', 'departmentId': '999'},
    ],
    'products': [
      {
        'id': '1',
        'name': 'Кофе',
        'unit': 'коробка',
        'inventoryUnit': 'кг',
        'categoryId': '10',
        'minStock': 2.5
      },
      {'id': '2', 'name': 'Чизкейк', 'unit': 'шт', 'categoryId': '11'},
      {'id': '3', 'name': '   '},
    ],
    'staff': ['Настя', '', 'Никита'],
  };

  final venue02Settings = {
    'establishmentName': 'Филиал',
    'currency': '₽',
    'departments': [
      {'id': '1', 'name': 'Склад', 'icon': Icons.warehouse.codePoint.toString()}
    ],
    'categories': [
      {'id': '1', 'name': 'Продукты', 'departmentId': '1'}
    ],
    'products': [
      {'id': '1', 'name': 'Мука', 'unit': 'кг', 'categoryId': '1'}
    ],
    'staff': ['Бэлла'],
  };

  Map<String, Object> fullDevice() => {
        'venues_list': jsonEncode([
          {'code': '01', 'name': 'Центр'},
          {'code': '02', 'name': 'Филиал на Абая'},
        ]),
        'settings_data': jsonEncode(venue01Settings),
        'settings_data_02': jsonEncode(venue02Settings),
        'history_data': jsonEncode([
          {
            'id': 'h1',
            'type': 'request',
            'title': 'Заявка: Бар',
            'text': 'Кофе — 2',
            'createdAt': '2026-09-01T10:00:00.000'
          },
          {'id': 'h2', 'type': 'inventory', 'title': 'Инв', 'text': 'x'},
          {'id': 'h3', 'type': 'request', 'title': null, 'text': 'битая'},
        ]),
        'shift_records': jsonEncode([
          {
            'date': '2026-09-02T22:00:00.000',
            'revenue': 15000.75,
            'qr': 5000,
            'card': 4000,
            'cash': 6000.5,
            'morningCash': 1000,
            'eveningCash': 7000,
            'writeOffs': {'Чизкейк': 2, 'Заготовка': 1, 'Ноль': 0},
          },
          {'revenue': 1}, // без даты — пропускается
        ]),
        'shift_records_02': jsonEncode([
          {'date': '2026-09-03T22:00:00.000', 'revenue': 300, 'writeOffs': {}}
        ]),
        'current_stock_levels': jsonEncode({'1': 1.5, '2': 4, 'нет': 3}),
        'notification_data': jsonEncode({
          'productReminders': [
            {
              'id': 1000,
              'productName': 'Молоко',
              'frequency': 'weekly',
              'hour': 9,
              'minute': 30,
              'weekday': 3
            }
          ],
          'inventoryReminder': {
            'enabled': true,
            'dayOfMonth': 25,
            'hour': 8,
            'minute': 0,
            'dayBeforeEnabled': false
          },
        }),
        'custom_inventory_template': jsonEncode({
          'name': 'Лист1',
          'columns': [],
          'createdAt': '2026-09-01T00:00:00.000'
        }),
      };

  test('переносит все заведения со своими данными', () async {
    final prefs = await prefsWith(fullDevice());
    final report = await LegacyMigration.run(db: db, prefs: prefs);

    expect(report.failures, isEmpty);
    expect(report.venues, 2);

    final venues = await catalog.loadVenues();
    expect(venues.map((v) => v.code), ['01', '02']);
    final v1 = venues[0];
    final v2 = venues[1];
    expect(v1.name, 'Центр');
    expect(v1.reportName, 'Спартак');
    expect(v1.showShiftDesserts, isFalse);
    expect(v2.reportName, 'Филиал');
    expect(v2.currency, '₽');

    final deps1 = await catalog.loadDepartments(v1.id);
    expect(deps1.map((d) => d.iconKey), ['local_bar', 'category']);
    final deps2 = await catalog.loadDepartments(v2.id);
    expect(deps2.single.iconKey, 'warehouse');

    // Данные заведений не смешиваются, хотя старые id совпадали ('1').
    final products2 = await catalog.loadProducts(v2.id);
    expect(products2.single.name, 'Мука');
    expect((await catalog.loadStaff(v2.id)).single.fullName, 'Бэлла');
    expect((await operations.loadShifts(v2.id)).single.revenueMinor, 30000);
  });

  test('связи и флаги справочника переносятся корректно', () async {
    final prefs = await prefsWith(fullDevice());
    final report = await LegacyMigration.run(db: db, prefs: prefs);
    final venueId = report.venueIds['01']!;

    final deps = await catalog.loadDepartments(venueId);
    final cats = await catalog.loadCategories(venueId);
    final products = await catalog.loadProducts(venueId);

    final bar = deps.firstWhere((d) => d.name == 'Бар');
    expect(
        cats
            .where((c) => c.name != 'Ничьё')
            .every((c) => c.departmentId == bar.id),
        isTrue);
    expect(cats.firstWhere((c) => c.name == 'Ничьё').departmentId, isNull);

    // Флаг десертов: по названию для старых данных, явный — как есть.
    expect(cats.firstWhere((c) => c.name == 'Десерты').isDessert, isTrue);
    expect(cats.firstWhere((c) => c.name == 'Сладкое').isDessert, isTrue);
    expect(cats.firstWhere((c) => c.name == 'Напитки').isDessert, isFalse);

    // Пустое название пропущено.
    expect(products.map((p) => p.name), ['Кофе', 'Чизкейк']);
    final coffee = products.first;
    expect(coffee.unit, 'коробка');
    expect(coffee.inventoryUnit, 'кг');
    expect(coffee.minStock, 2.5);
    expect(coffee.categoryId, cats.firstWhere((c) => c.name == 'Напитки').id);

    final staff = await catalog.loadStaff(venueId);
    expect(staff.map((s) => s.fullName), ['Настя', 'Никита']);
    expect(staff.every((s) => s.pinHash == null && s.role == 'staff'), isTrue);
  });

  test('история, смены, списания, остатки, напоминания, шаблон', () async {
    final prefs = await prefsWith(fullDevice());
    final report = await LegacyMigration.run(db: db, prefs: prefs);
    final v1 = report.venueIds['01']!;
    final v2 = report.venueIds['02']!;

    final history = await operations.loadHistory(v1);
    expect(history.length, 2); // запись без заголовка пропущена
    expect(history.map((h) => h.kind).toSet(), {'request', 'inventory'});

    final shift = (await operations.loadShifts(v1)).single;
    expect(shift.revenueMinor, 1500075);
    expect(shift.cashMinor, 600050);
    final writeoffs = await operations.loadWriteoffs(shift.id);
    expect(
        writeoffs.map((w) => w.productName).toSet(), {'Чизкейк', 'Заготовка'});
    final products = await catalog.loadProducts(v1);
    final cheesecake = products.firstWhere((p) => p.name == 'Чизкейк');
    expect(writeoffs.firstWhere((w) => w.productName == 'Чизкейк').productId,
        cheesecake.id);
    expect(writeoffs.firstWhere((w) => w.productName == 'Заготовка').productId,
        isNull);

    // Общий ключ остатков — только заведению 01, с переписанными id.
    final stock = await operations.loadStockLevels(v1);
    expect(stock.length, 2);
    expect(stock[products.firstWhere((p) => p.name == 'Кофе').id], 1.5);
    expect(await operations.loadStockLevels(v2), isEmpty);

    final reminders = await operations.loadReminders(v1);
    expect(reminders.length, 2);
    final weekly = reminders.firstWhere((r) => r.frequency == 'weekly');
    expect(weekly.notificationId, 1000);
    expect(weekly.weekday, 3);
    final monthly = reminders.firstWhere((r) => r.frequency == 'monthly');
    expect(monthly.dayOfMonth, 25);
    expect(monthly.remindDayBefore, isFalse);
    expect(await operations.loadReminders(v2), isEmpty);

    // Общий шаблон копируется в каждое заведение.
    expect((await operations.loadTemplate(v1))?.name, 'Лист1');
    expect((await operations.loadTemplate(v2))?.name, 'Лист1');
  });

  test('без списка заведений переносится одно заведение 01', () async {
    final prefs = await prefsWith({
      'settings_data': jsonEncode(venue01Settings),
    });
    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.venues, 1);
    final venue = (await catalog.loadVenues()).single;
    expect(venue.code, '01');
    expect(venue.reportName, 'Спартак');
  });

  test('чистое устройство: одно пустое заведение, без сбоев', () async {
    final prefs = await prefsWith({});
    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.failures, isEmpty);
    expect(report.venues, 1);
    expect(report.products, 0);
  });

  test('испорченный JSON раздела не роняет перенос остальных', () async {
    final prefs = await prefsWith({
      ...fullDevice(),
      'history_data': '{не json',
    });
    final report = await LegacyMigration.run(db: db, prefs: prefs);
    expect(report.failures, isNotEmpty);
    expect(report.history, 0);
    expect(report.products, 3);
  });

  test('выполняется один раз, повтор — только с force', () async {
    final prefs = await prefsWith(fullDevice());
    await LegacyMigration.run(db: db, prefs: prefs);
    expect(LegacyMigration.isDone(prefs), isTrue);

    final second = await LegacyMigration.run(db: db, prefs: prefs);
    expect(second.skipped, isTrue);
    expect((await catalog.loadVenues()).length, 2);
  });

  test('старые ключи не удаляются', () async {
    final prefs = await prefsWith(fullDevice());
    await LegacyMigration.run(db: db, prefs: prefs);
    expect(prefs.getString('settings_data'), isNotNull);
    expect(prefs.getString('settings_data_02'), isNotNull);
  });
}
