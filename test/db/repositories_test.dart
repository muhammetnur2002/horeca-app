import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/backup/data/backup_service.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_products.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Репозитории поверх базы: изменение, сделанное через репозиторий,
/// должно оказаться в базе и пережить «перезапуск» (новый экземпляр).
void main() {
  late AppDatabase db;
  late CatalogDao catalog;
  late OperationsDao operations;
  late String venueId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogDao(db);
    operations = OperationsDao(db);
    venueId = await catalog.upsertVenue(code: '01', name: 'Центр');
  });

  tearDown(() => db.close());

  /// Записи в базу идут без ожидания — даём им завершиться.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  Future<SettingsRepository> freshSettings() async {
    final repo = SettingsRepository(catalog, venueId);
    await repo.ready;
    return repo;
  }

  test('новое заведение пустое — без демонстрационных данных', () async {
    final repo = await freshSettings();
    expect(repo.data.departments, isEmpty);
    expect(repo.data.products, isEmpty);
    expect(repo.data.staff, isEmpty);
    expect(repo.data.establishmentName, isNot('Спартак'));
  });

  test('каталог сохраняется в базе и переживает перезапуск', () async {
    final repo = await freshSettings();
    repo.addDepartment('Бар', Icons.local_bar);
    final deptId = repo.data.departments.single.id;
    repo.addCategory('Десерты', deptId, isDessertCategory: true);
    final catId = repo.data.categories.single.id;
    repo.addProduct('Чизкейк', 'шт', catId);
    final productId = repo.data.products.single.id;
    repo.setProductMinStock(productId, 3);
    repo.updateProduct(productId, 'Чизкейк классический', 'шт');
    repo.addStaff('Настя');
    repo.updateStaff('Настя', 'Анастасия');
    repo.setEstablishmentName('Кофейня');
    repo.setCurrency('₽');
    await settle();

    final again = await freshSettings();
    final data = again.data;
    expect(data.departments.single.name, 'Бар');
    expect(data.departments.single.icon, Icons.local_bar);
    expect(data.categories.single.isDessertCategory, isTrue);
    expect(data.products.single.name, 'Чизкейк классический');
    // Редактирование товара не стирает минимальный остаток.
    expect(data.products.single.minStock, 3);
    expect(data.staff, ['Анастасия']);
    expect(data.establishmentName, 'Кофейня');
    expect(data.currency, '₽');
  });

  test('удаление отдела убирает его категории и товары и в базе', () async {
    final repo = await freshSettings();
    repo.addDepartment('Бар', Icons.local_bar);
    final deptId = repo.data.departments.single.id;
    repo.addCategory('Напитки', deptId);
    repo.addProduct('Кола', 'л', repo.data.categories.single.id);
    await settle();
    repo.deleteDepartment(deptId);
    await settle();

    final again = await freshSettings();
    expect(again.data.departments, isEmpty);
    expect(again.data.categories, isEmpty);
    expect(again.data.products, isEmpty);
  });

  test('история: новые сверху, очистка по типу', () async {
    final repo = HistoryRepository(operations, venueId);
    await repo.ready;
    repo.add(HistoryEntry(
        id: 'a',
        type: HistoryType.request,
        title: 'Заявка 1',
        text: '',
        createdAt: DateTime(2026, 10, 1)));
    repo.add(HistoryEntry(
        id: 'b',
        type: HistoryType.inventory,
        title: 'Инвентаризация',
        text: '',
        createdAt: DateTime(2026, 10, 2)));
    await settle();

    final again = HistoryRepository(operations, venueId);
    await again.ready;
    expect(again.getAll().map((e) => e.title), ['Инвентаризация', 'Заявка 1']);

    again.clearByType(HistoryType.inventory);
    await settle();
    final third = HistoryRepository(operations, venueId);
    await third.ready;
    expect(third.getAll().single.title, 'Заявка 1');
  });

  test('смена сохраняется в копейках и с id не дублируется', () async {
    final repo = AnalyticsRepository(operations, venueId);
    await repo.ready;
    final record = ShiftRecord(
      date: DateTime(2026, 10, 1, 22),
      revenue: 15000.75,
      cash: 0.1 + 0.2,
      writeOffs: {'Чизкейк': 2},
    );
    repo.addShift(record, shiftId: 's1', staffNames: ['Настя']);
    repo.addShift(record, shiftId: 's1');
    await settle();

    final again = AnalyticsRepository(operations, venueId);
    await again.ready;
    final shift = again.getAll().single;
    expect(shift.revenue, 15000.75);
    expect(shift.cash, 0.3);
    expect(shift.writeOffs, {'Чизкейк': 2});
  });

  test('бэкап: выгрузка и восстановление без потерь', () async {
    final repo = await freshSettings();
    repo.addDepartment('Склад', Icons.warehouse);
    repo.addStaff('Никита');
    await settle();

    final backup = jsonDecode(jsonEncode(await BackupService.exportData(db)))
        as Map<String, dynamic>;

    // Портим данные и восстанавливаем.
    repo.deleteStaff('Никита');
    await settle();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final result = await BackupService.importData(backup, db, prefs);
    expect(result, RestoreResult.success);

    final again = await freshSettings();
    expect(again.data.departments.single.name, 'Склад');
    expect(again.data.staff, ['Никита']);
  });

  test('бэкап старого формата восстанавливается через перенос', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final legacy = {
      'app': 'Akyl',
      'version': '1.0.0',
      'data': {
        'venues_list': jsonEncode([
          {'code': '01', 'name': 'Центр'}
        ]),
        'settings_data': jsonEncode({
          'establishmentName': 'Старое',
          'departments': [
            {'id': '1', 'name': 'Кухня', 'icon': '0'}
          ],
          'categories': [],
          'products': [],
          'staff': ['Медина'],
        }),
      },
    };
    final result = await BackupService.importData(legacy, db, prefs);
    expect(result, RestoreResult.success);

    final venue = (await catalog.loadVenues()).single;
    expect(venue.reportName, 'Старое');
    expect((await catalog.loadStaff(venue.id)).single.fullName, 'Медина');
  });

  test('чужой файл не принимается', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final result =
        await BackupService.importData({'app': 'Другое'}, db, prefs);
    expect(result, RestoreResult.invalidFile);
  });
}
