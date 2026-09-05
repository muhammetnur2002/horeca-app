import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';

/// Проверки слоя доступа к базе.
///
/// Каждый тест поднимает базу в памяти: файл на диске здесь не нужен,
/// а тесты не зависят друг от друга.
void main() {
  late AppDatabase db;
  late CatalogDao catalog;
  late OperationsDao operations;
  late String establishment;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogDao(db);
    operations = OperationsDao(db);
    establishment = await catalog.currentEstablishmentId();
  });

  tearDown(() => db.close());

  group('Справочники', () {
    test('заведение создаётся один раз', () async {
      final again = await catalog.currentEstablishmentId();
      expect(again, establishment);

      final row = await catalog.loadEstablishment();
      expect(row, isNotNull);
      expect(row!.currency, '₸');
    });

    test('удалённый отдел пропадает из выдачи, но остаётся в базе', () async {
      final id = await catalog.upsertDepartment(
        establishmentId: establishment,
        name: 'Бар',
      );
      expect((await catalog.loadDepartments(establishment)).length, 1);

      await catalog.deleteDepartment(id);
      expect(await catalog.loadDepartments(establishment), isEmpty);

      // Строка на месте — иначе устройство, которое было оффлайн,
      // никогда не узнает об удалении.
      final raw = await (db.select(db.departments)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(raw.deletedAt, isNotNull);
    });

    test('повторный upsert по тому же id меняет строку, а не добавляет',
        () async {
      final id = await catalog.upsertDepartment(
        establishmentId: establishment,
        name: 'Кухня',
      );
      await catalog.upsertDepartment(
        establishmentId: establishment,
        id: id,
        name: 'Горячий цех',
      );

      final all = await catalog.loadDepartments(establishment);
      expect(all.length, 1);
      expect(all.single.name, 'Горячий цех');
    });

    test('отделы отдаются в заданном порядке', () async {
      await catalog.upsertDepartment(
          establishmentId: establishment, name: 'Второй', sortOrder: 2);
      await catalog.upsertDepartment(
          establishmentId: establishment, name: 'Первый', sortOrder: 1);

      final names =
          (await catalog.loadDepartments(establishment)).map((d) => d.name);
      expect(names, ['Первый', 'Второй']);
    });

    test('очистка помечает удалёнными товары, категории и сотрудников',
        () async {
      await catalog.upsertCategory(
          establishmentId: establishment, name: 'Напитки');
      await catalog.upsertProduct(
          establishmentId: establishment, name: 'Кофе');
      await catalog.upsertStaffMember(
          establishmentId: establishment, fullName: 'Айгуль');

      await catalog.clearCatalog(establishment);

      expect(await catalog.loadCategories(establishment), isEmpty);
      expect(await catalog.loadProducts(establishment), isEmpty);
      expect(await catalog.loadStaff(establishment), isEmpty);
    });

    test('массовая вставка товаров сохраняет все строки', () async {
      final now = DateTime.now().toUtc();
      await catalog.insertProducts([
        for (var i = 0; i < 40; i++)
          ProductsCompanion.insert(
            id: 'bulk-$i',
            createdAt: now,
            updatedAt: now,
            establishmentId: establishment,
            name: 'Товар $i',
          ),
      ]);

      expect((await catalog.loadProducts(establishment)).length, 40);
    });
  });

  group('Журнал', () {
    test('записи отдаются от новых к старым', () async {
      final base = DateTime.utc(2026, 1, 1);
      for (var i = 0; i < 3; i++) {
        await operations.addHistoryEntry(
          establishmentId: establishment,
          kind: 'request',
          title: 'Заявка $i',
          body: 'тело',
          createdAt: base.add(Duration(days: i)),
        );
      }

      final titles =
          (await operations.loadHistory(establishment)).map((e) => e.title);
      expect(titles, ['Заявка 2', 'Заявка 1', 'Заявка 0']);
    });

    test('журнал не растёт бесконечно', () async {
      final base = DateTime.utc(2026, 1, 1);
      for (var i = 0; i < OperationsDao.historyLimit + 12; i++) {
        await operations.addHistoryEntry(
          establishmentId: establishment,
          kind: 'request',
          title: 'Заявка $i',
          body: 'тело',
          createdAt: base.add(Duration(minutes: i)),
        );
      }

      final kept = await operations.loadHistory(establishment);
      expect(kept.length, OperationsDao.historyLimit);
      // Обрезается самое старое, а не самое новое.
      expect(kept.first.title, 'Заявка ${OperationsDao.historyLimit + 11}');
      expect(kept.last.title, 'Заявка 12');
    });
  });

  group('Смены', () {
    test('повторная отправка не создаёт дубль и не меняет сумму', () async {
      final id = await operations.addShift(
        establishmentId: establishment,
        closedAt: DateTime.utc(2026, 3, 1, 22),
        staffNames: ['Айгуль', 'Данияр'],
        revenueMinor: 15000000,
      );

      final again = await operations.addShift(
        establishmentId: establishment,
        id: id,
        closedAt: DateTime.utc(2026, 3, 1, 22),
        staffNames: ['Кто-то другой'],
        revenueMinor: 1,
      );

      expect(again, id);
      final shifts = await operations.loadShifts(establishment);
      expect(shifts.length, 1);
      expect(shifts.single.revenueMinor, 15000000);
    });

    test('списания пишутся вместе со сменой', () async {
      final id = await operations.addShift(
        establishmentId: establishment,
        closedAt: DateTime.utc(2026, 3, 2, 22),
        staffNames: ['Айгуль'],
        revenueMinor: 100,
        writeoffs: {'Молоко': 2.5, 'Сироп': 0},
        writeoffUnits: {'Молоко': 'л'},
      );

      final writeoffs = await operations.loadWriteoffs(id);
      // Нулевое списание — это не списание.
      expect(writeoffs.length, 1);
      expect(writeoffs.single.productName, 'Молоко');
      expect(writeoffs.single.quantity, 2.5);
      expect(writeoffs.single.unit, 'л');
    });
  });

  group('Остатки', () {
    test('позднее измерение перезаписывает раннее', () async {
      final product = await catalog.upsertProduct(
          establishmentId: establishment, name: 'Кофе');

      await operations.saveStockLevels(
        establishmentId: establishment,
        levels: {product: 10},
        measuredAt: DateTime.utc(2026, 3, 1),
      );
      await operations.saveStockLevels(
        establishmentId: establishment,
        levels: {product: 4},
        measuredAt: DateTime.utc(2026, 3, 2),
      );

      expect(await operations.loadStockLevels(establishment), {product: 4.0});
    });

    test('раннее измерение не затирает позднее', () async {
      final product = await catalog.upsertProduct(
          establishmentId: establishment, name: 'Кофе');

      await operations.saveStockLevels(
        establishmentId: establishment,
        levels: {product: 4},
        measuredAt: DateTime.utc(2026, 3, 2),
      );
      // Устройство было оффлайн и прислало вчерашний замер сегодня.
      await operations.saveStockLevels(
        establishmentId: establishment,
        levels: {product: 10},
        measuredAt: DateTime.utc(2026, 3, 1),
      );

      expect(await operations.loadStockLevels(establishment), {product: 4.0});
    });
  });
}
