import 'package:drift/drift.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';

/// Доступ к настройкам заведения и справочникам.
///
/// Слой намеренно тонкий: он умеет читать и писать строки, но не знает
/// ни о каких экранах и не хранит состояние. Решения о том, что показать
/// пользователю, остаются в репозиториях.
///
/// updated_at везде проставляется явно. В SQLite нет триггеров, которыми
/// это делает сервер, а метка нужна синхронизации: без неё изменение
/// не попадёт в выборку «что поменялось после».
class CatalogDao {
  CatalogDao(this._db);

  final AppDatabase _db;

  static DateTime _now() => DateTime.now().toUtc();

  // ── Заведение ──────────────────────────────────────────────────────────────

  /// Идентификатор текущего заведения. Строка ровно одна; если её ещё нет,
  /// она создаётся при первом обращении.
  Future<String> currentEstablishmentId() async {
    final existing =
        await _db.select(_db.establishmentSettings).getSingleOrNull();
    if (existing != null) return existing.id;

    final now = _now();
    final id = Ids.newId();
    await _db.into(_db.establishmentSettings).insert(
          EstablishmentSettingsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            currency: '₸',
          ),
        );
    return id;
  }

  Future<EstablishmentRow?> loadEstablishment() =>
      _db.select(_db.establishmentSettings).getSingleOrNull();

  Future<void> saveEstablishment({
    required String id,
    String? name,
    String? currency,
    String? logoPath,
    bool clearLogo = false,
  }) async {
    await (_db.update(_db.establishmentSettings)..where((t) => t.id.equals(id)))
        .write(
      EstablishmentSettingsCompanion(
        name: name == null ? const Value.absent() : Value(name),
        currency: currency == null ? const Value.absent() : Value(currency),
        logoPath: clearLogo
            ? const Value(null)
            : (logoPath == null ? const Value.absent() : Value(logoPath)),
        updatedAt: Value(_now()),
      ),
    );
  }

  // ── Отделы ─────────────────────────────────────────────────────────────────

  Future<List<DepartmentRow>> loadDepartments(String establishmentId) {
    final query = _db.select(_db.departments)
      ..where((t) =>
          t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.get();
  }

  Future<String> upsertDepartment({
    required String establishmentId,
    String? id,
    required String name,
    String iconKey = 'category',
    int sortOrder = 0,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    await _db.into(_db.departments).insertOnConflictUpdate(
          DepartmentsCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            establishmentId: establishmentId,
            name: name,
            iconKey: Value(iconKey),
            sortOrder: Value(sortOrder),
          ),
        );
    return rowId;
  }

  /// Мягкое удаление: строка остаётся, но помечается удалённой.
  /// Физическое удаление невозможно синхронизировать — устройство,
  /// которое было оффлайн, не узнает об исчезнувшей строке.
  Future<void> deleteDepartment(String id) async {
    final now = _now();
    await (_db.update(_db.departments)..where((t) => t.id.equals(id))).write(
      DepartmentsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ── Категории ──────────────────────────────────────────────────────────────

  Future<List<CategoryRow>> loadCategories(String establishmentId) {
    final query = _db.select(_db.categories)
      ..where((t) =>
          t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.get();
  }

  Future<String> upsertCategory({
    required String establishmentId,
    String? id,
    required String name,
    String? departmentId,
    int sortOrder = 0,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    await _db.into(_db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            establishmentId: establishmentId,
            name: name,
            departmentId: Value(departmentId),
            sortOrder: Value(sortOrder),
          ),
        );
    return rowId;
  }

  Future<void> deleteCategory(String id) async {
    final now = _now();
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ── Товары ─────────────────────────────────────────────────────────────────

  Future<List<ProductRow>> loadProducts(String establishmentId) {
    final query = _db.select(_db.products)
      ..where((t) =>
          t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.get();
  }

  Future<String> upsertProduct({
    required String establishmentId,
    String? id,
    required String name,
    String unit = 'шт',
    String inventoryUnit = 'шт',
    String? categoryId,
    double? minStock,
    int sortOrder = 0,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            establishmentId: establishmentId,
            name: name,
            unit: Value(unit),
            inventoryUnit: Value(inventoryUnit),
            categoryId: Value(categoryId),
            minStock: Value(minStock),
            sortOrder: Value(sortOrder),
          ),
        );
    return rowId;
  }

  Future<void> deleteProduct(String id) async {
    final now = _now();
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Массовая вставка одной транзакцией. Экран массового добавления заводит
  /// товары десятками, и отдельная запись на каждый — десятки обращений
  /// к диску вместо одного.
  Future<void> insertProducts(List<ProductsCompanion> rows) async {
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.products, rows);
    });
  }

  // ── Сотрудники ─────────────────────────────────────────────────────────────

  Future<List<StaffMemberRow>> loadStaff(String establishmentId) {
    final query = _db.select(_db.staffMembers)
      ..where((t) =>
          t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.get();
  }

  Future<String> upsertStaffMember({
    required String establishmentId,
    String? id,
    required String fullName,
    bool isActive = true,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    await _db.into(_db.staffMembers).insertOnConflictUpdate(
          StaffMembersCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            establishmentId: establishmentId,
            fullName: fullName,
            isActive: Value(isActive),
          ),
        );
    return rowId;
  }

  Future<void> deleteStaffMember(String id) async {
    final now = _now();
    await (_db.update(_db.staffMembers)..where((t) => t.id.equals(id))).write(
      StaffMembersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ── Очистка ────────────────────────────────────────────────────────────────

  /// Соответствует кнопке «очистить все данные» в настройках.
  /// Удаление мягкое, как и везде.
  Future<void> clearCatalog(String establishmentId) async {
    final now = _now();
    await _db.transaction(() async {
      await (_db.update(_db.categories)
            ..where((t) =>
                t.establishmentId.equals(establishmentId) &
                t.deletedAt.isNull()))
          .write(
              CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));

      await (_db.update(_db.products)
            ..where((t) =>
                t.establishmentId.equals(establishmentId) &
                t.deletedAt.isNull()))
          .write(
              ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)));

      await (_db.update(_db.staffMembers)
            ..where((t) =>
                t.establishmentId.equals(establishmentId) &
                t.deletedAt.isNull()))
          .write(StaffMembersCompanion(
              deletedAt: Value(now), updatedAt: Value(now)));
    });
  }
}
