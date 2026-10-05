import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';

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

  test('обновление записи сохраняет дату создания', () async {
    final id = await catalog.upsertProduct(venueId: venueId, name: 'Кофе');
    final before = (await catalog.loadProducts(venueId)).single;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await catalog.upsertProduct(
        venueId: venueId, id: id, name: 'Кофе зерновой', minStock: 2);
    final after = (await catalog.loadProducts(venueId)).single;
    expect(after.name, 'Кофе зерновой');
    expect(after.minStock, 2);
    expect(after.createdAt, before.createdAt);
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
  });

  test('удаление отдела мягко удаляет его категории и товары', () async {
    final dept = await catalog.upsertDepartment(venueId: venueId, name: 'Бар');
    final other = await catalog.upsertDepartment(venueId: venueId, name: 'Зал');
    final cat = await catalog.upsertCategory(
        venueId: venueId, name: 'Напитки', departmentId: dept);
    final otherCat = await catalog.upsertCategory(
        venueId: venueId, name: 'Упаковка', departmentId: other);
    await catalog.upsertProduct(
        venueId: venueId, name: 'Кола', categoryId: cat);
    await catalog.upsertProduct(
        venueId: venueId, name: 'Пакеты', categoryId: otherCat);

    await catalog.deleteDepartment(dept);

    expect((await catalog.loadDepartments(venueId)).single.name, 'Зал');
    expect((await catalog.loadCategories(venueId)).single.name, 'Упаковка');
    expect((await catalog.loadProducts(venueId)).single.name, 'Пакеты');
    // Строки остались в базе — для синхронизации.
    expect((await db.select(db.products).get()).length, 2);
  });

  test('данные разных заведений не смешиваются', () async {
    final v2 = await catalog.upsertVenue(code: '02', name: 'Филиал');
    await catalog.upsertProduct(venueId: venueId, name: 'Кофе');
    await catalog.upsertProduct(venueId: v2, name: 'Мука');
    expect((await catalog.loadProducts(venueId)).single.name, 'Кофе');
    expect((await catalog.loadProducts(v2)).single.name, 'Мука');
  });

  test('повторная запись смены с тем же id ничего не дублирует', () async {
    Future<String> add() => operations.addShift(
          venueId: venueId,
          id: 'shift-1',
          closedAt: DateTime(2026, 10, 1, 22),
          staffNames: ['Настя'],
          revenueMinor: 100000,
          writeoffs: const [
            ShiftWriteoffInput(productName: 'Чизкейк', quantity: 2),
            ShiftWriteoffInput(productName: 'Ноль', quantity: 0),
          ],
        );
    await add();
    await add();
    final shifts = await operations.loadShifts(venueId);
    expect(shifts.length, 1);
    expect((await operations.loadWriteoffs('shift-1')).single.productName,
        'Чизкейк');
  });

  test('история ограничена и отдаётся от новых к старым', () async {
    for (var i = 0; i < OperationsDao.historyLimit + 3; i++) {
      await operations.addHistoryEntry(
        venueId: venueId,
        kind: 'request',
        title: 'Заявка $i',
        body: '',
        createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
      );
    }
    final history = await operations.loadHistory(venueId);
    expect(history.length, OperationsDao.historyLimit);
    expect(history.first.title, 'Заявка ${OperationsDao.historyLimit + 2}');
  });

  test('более раннее измерение остатка не затирает более позднее', () async {
    await operations.saveStockLevels(
        venueId: venueId,
        levels: {'p1': 5},
        measuredAt: DateTime.utc(2026, 10, 2));
    await operations.saveStockLevels(
        venueId: venueId,
        levels: {'p1': 9},
        measuredAt: DateTime.utc(2026, 10, 1));
    expect((await operations.loadStockLevels(venueId))['p1'], 5);
  });

  test('журнал движений: повтор по id гасится, фильтр по периоду', () async {
    final movements = [
      StockMovementInput(
          id: 'm1',
          venueId: venueId,
          productId: 'p1',
          kind: 'baseline',
          quantity: 10,
          occurredAt: DateTime.utc(2026, 10, 1)),
      StockMovementInput(
          id: 'm2',
          venueId: venueId,
          productId: 'p1',
          kind: 'receipt',
          quantity: 5,
          occurredAt: DateTime.utc(2026, 10, 3)),
      StockMovementInput(
          id: 'm3',
          venueId: venueId,
          productId: 'p1',
          kind: 'sale',
          quantity: -4,
          occurredAt: DateTime.utc(2026, 10, 5)),
    ];
    await operations.addMovements(movements);
    await operations.addMovements(movements);

    final all = await operations.loadMovements(venueId, productId: 'p1');
    expect(all.length, 3);
    expect(all.fold<double>(0, (s, m) => s + m.quantity), 11);

    final period = await operations.loadMovements(venueId,
        from: DateTime.utc(2026, 10, 2), to: DateTime.utc(2026, 10, 5));
    expect(period.map((m) => m.id), ['m2']);
  });

  test('журнал изменений хранит было/стало и причину', () async {
    await operations.addAudit(
      venueId: venueId,
      staffId: 's1',
      entity: 'receipt',
      entityId: 'r1',
      action: 'update',
      beforeJson: '{"qty":10}',
      afterJson: '{"qty":12}',
      reason: 'пересчитали коробку',
    );
    final log = await operations.loadAudit(venueId, entityId: 'r1');
    expect(log.single.beforeJson, '{"qty":10}');
    expect(log.single.reason, 'пересчитали коробку');
  });
}
