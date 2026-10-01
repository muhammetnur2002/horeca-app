import 'package:drift/drift.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';

/// Доступ к заведениям и справочникам: отделы, категории, товары,
/// сотрудники.
///
/// Слой тонкий: читает и пишет строки, не знает об экранах и не хранит
/// состояние. updatedAt проставляется явно — в SQLite нет триггеров,
/// а метка нужна синхронизации («что поменялось после»).
class CatalogDao {
  CatalogDao(this._db);

  final AppDatabase _db;

  static DateTime _now() => DateTime.now().toUtc();

  // ── Заведения ──────────────────────────────────────────────────────────────

  Future<List<VenueRow>> loadVenues() {
    final query = _db.select(_db.venues)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.code)]);
    return query.get();
  }

  Future<VenueRow?> venueByCode(String code) {
    final query = _db.select(_db.venues)
      ..where((t) => t.code.equals(code) & t.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  Future<String> upsertVenue({
    String? id,
    required String code,
    required String name,
    String reportName = 'Моё заведение',
    String currency = '₸',
    String? logoPath,
    bool showShiftDesserts = true,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    final row = VenuesCompanion.insert(
      id: rowId,
      createdAt: now,
      updatedAt: now,
      code: code,
      name: name,
      reportName: Value(reportName),
      currency: currency,
      logoPath: Value(logoPath),
      showShiftDesserts: Value(showShiftDesserts),
    );
    // При обновлении дата создания остаётся прежней.
    await _db.into(_db.venues).insert(row,
        onConflict:
            DoUpdate((_) => row.copyWith(createdAt: const Value.absent())));
    return rowId;
  }

  /// Частичное обновление полей заведения (не переданные — не меняются).
  Future<void> updateVenue(
    String id, {
    String? name,
    String? reportName,
    String? currency,
    String? logoPath,
    bool clearLogo = false,
    bool? showShiftDesserts,
  }) async {
    await (_db.update(_db.venues)..where((t) => t.id.equals(id))).write(
      VenuesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        reportName:
            reportName == null ? const Value.absent() : Value(reportName),
        currency: currency == null ? const Value.absent() : Value(currency),
        logoPath: clearLogo
            ? const Value(null)
            : (logoPath == null ? const Value.absent() : Value(logoPath)),
        showShiftDesserts: showShiftDesserts == null
            ? const Value.absent()
            : Value(showShiftDesserts),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Мягкое удаление заведения вместе со всеми его справочниками.
  Future<void> deleteVenue(String venueId) async {
    final now = _now();
    await _db.transaction(() async {
      await (_db.update(_db.venues)..where((t) => t.id.equals(venueId)))
          .write(VenuesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.departments)
            ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull()))
          .write(DepartmentsCompanion(
              deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.categories)
            ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull()))
          .write(CategoriesCompanion(
              deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.products)
            ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull()))
          .write(
              ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.staffMembers)
            ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull()))
          .write(StaffMembersCompanion(
              deletedAt: Value(now), updatedAt: Value(now)));
    });
  }

  // ── Отделы ─────────────────────────────────────────────────────────────────

  Future<List<DepartmentRow>> loadDepartments(String venueId) {
    final query = _db.select(_db.departments)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.get();
  }

  Future<String> upsertDepartment({
    required String venueId,
    String? id,
    required String name,
    String iconKey = 'category',
    int? sortOrder,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    final row = DepartmentsCompanion.insert(
      id: rowId,
      createdAt: now,
      updatedAt: now,
      venueId: venueId,
      name: name,
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder ?? 0),
    );
    // При обновлении дата создания остаётся прежней.
    await _db.into(_db.departments).insert(row,
        onConflict: DoUpdate((_) => row.copyWith(
            createdAt: const Value.absent(),
            // Без явного порядка при обновлении сохраняем прежний.
            sortOrder:
                sortOrder == null ? const Value.absent() : Value(sortOrder))));
    return rowId;
  }

  /// Мягкое удаление отдела вместе с его категориями и их товарами —
  /// так же, как это делает текущий экран настроек.
  Future<void> deleteDepartment(String id) async {
    final now = _now();
    await _db.transaction(() async {
      final categoryIds = await (_db.selectOnly(_db.categories)
            ..addColumns([_db.categories.id])
            ..where(_db.categories.departmentId.equals(id) &
                _db.categories.deletedAt.isNull()))
          .map((row) => row.read(_db.categories.id)!)
          .get();
      await (_db.update(_db.departments)..where((t) => t.id.equals(id))).write(
          DepartmentsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      if (categoryIds.isEmpty) return;
      await (_db.update(_db.categories)..where((t) => t.id.isIn(categoryIds)))
          .write(CategoriesCompanion(
              deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.products)
            ..where(
                (t) => t.categoryId.isIn(categoryIds) & t.deletedAt.isNull()))
          .write(
              ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    });
  }

  // ── Категории ──────────────────────────────────────────────────────────────

  Future<List<CategoryRow>> loadCategories(String venueId) {
    final query = _db.select(_db.categories)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.get();
  }

  Future<String> upsertCategory({
    required String venueId,
    String? id,
    required String name,
    String? departmentId,
    bool isDessert = false,
    int? sortOrder,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    final row = CategoriesCompanion.insert(
      id: rowId,
      createdAt: now,
      updatedAt: now,
      venueId: venueId,
      name: name,
      departmentId: Value(departmentId),
      isDessert: Value(isDessert),
      sortOrder: Value(sortOrder ?? 0),
    );
    // При обновлении дата создания остаётся прежней.
    await _db.into(_db.categories).insert(row,
        onConflict: DoUpdate((_) => row.copyWith(
            createdAt: const Value.absent(),
            // Без явного порядка при обновлении сохраняем прежний.
            sortOrder:
                sortOrder == null ? const Value.absent() : Value(sortOrder))));
    return rowId;
  }

  /// Мягкое удаление категории вместе с её товарами.
  Future<void> deleteCategory(String id) async {
    final now = _now();
    await _db.transaction(() async {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
          CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.products)
            ..where((t) => t.categoryId.equals(id) & t.deletedAt.isNull()))
          .write(
              ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    });
  }

  // ── Товары ─────────────────────────────────────────────────────────────────

  Future<List<ProductRow>> loadProducts(String venueId) {
    final query = _db.select(_db.products)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.get();
  }

  Future<String> upsertProduct({
    required String venueId,
    String? id,
    required String name,
    String unit = 'шт',
    String inventoryUnit = 'шт',
    double unitFactor = 1,
    String? categoryId,
    double? minStock,
    String? iikoProductId,
    int? sortOrder,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    final row = ProductsCompanion.insert(
      id: rowId,
      createdAt: now,
      updatedAt: now,
      venueId: venueId,
      name: name,
      unit: Value(unit),
      inventoryUnit: Value(inventoryUnit),
      unitFactor: Value(unitFactor),
      categoryId: Value(categoryId),
      minStock: Value(minStock),
      iikoProductId: Value(iikoProductId),
      sortOrder: Value(sortOrder ?? 0),
    );
    // При обновлении дата создания остаётся прежней.
    await _db.into(_db.products).insert(row,
        onConflict: DoUpdate((_) => row.copyWith(
            createdAt: const Value.absent(),
            // Без явного порядка при обновлении сохраняем прежний.
            sortOrder:
                sortOrder == null ? const Value.absent() : Value(sortOrder))));
    return rowId;
  }

  Future<void> deleteProduct(String id) async {
    final now = _now();
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Массовая вставка одной транзакцией (массовое добавление, импорт iiko).
  Future<void> insertProducts(List<ProductsCompanion> rows) async {
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.products, rows);
    });
  }

  // ── Сотрудники ─────────────────────────────────────────────────────────────

  Future<List<StaffMemberRow>> loadStaff(String venueId) {
    final query = _db.select(_db.staffMembers)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.get();
  }

  Future<String> upsertStaffMember({
    required String venueId,
    String? id,
    required String fullName,
    String role = 'staff',
    String? pinHash,
    String? pinSalt,
    bool isActive = true,
  }) async {
    final now = _now();
    final rowId = id ?? Ids.newId();
    final row = StaffMembersCompanion.insert(
      id: rowId,
      createdAt: now,
      updatedAt: now,
      venueId: venueId,
      fullName: fullName,
      role: Value(role),
      pinHash: Value(pinHash),
      pinSalt: Value(pinSalt),
      isActive: Value(isActive),
    );
    // При обновлении дата создания остаётся прежней.
    await _db.into(_db.staffMembers).insert(row,
        onConflict:
            DoUpdate((_) => row.copyWith(createdAt: const Value.absent())));
    return rowId;
  }

  Future<void> deleteStaffMember(String id) async {
    final now = _now();
    await (_db.update(_db.staffMembers)..where((t) => t.id.equals(id))).write(
      StaffMembersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}
