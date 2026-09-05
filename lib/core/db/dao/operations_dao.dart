import 'package:drift/drift.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';

/// Доступ к операциям: журнал документов, закрытые смены, остатки.
///
/// Операции, в отличие от справочников, не редактируются: закрытая смена
/// это факт. Поэтому здесь нет методов обновления — только добавление
/// и чтение.
class OperationsDao {
  OperationsDao(this._db);

  final AppDatabase _db;

  static DateTime _now() => DateTime.now().toUtc();

  /// Верхняя граница журнала. Раньше история росла без ограничений
  /// и замедляла запуск: SharedPreferences читался целиком.
  static const historyLimit = 500;

  // ── Журнал заявок и инвентаризаций ─────────────────────────────────────────

  /// Записи от новых к старым — в таком порядке их показывает экран истории.
  Future<List<HistoryEntryRow>> loadHistory(String establishmentId) {
    final query = _db.select(_db.historyEntries)
      ..where((t) =>
          t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(
            expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  Future<String> addHistoryEntry({
    required String establishmentId,
    required String kind,
    required String title,
    required String body,
    DateTime? createdAt,
  }) async {
    final now = _now();
    final id = Ids.newId();
    await _db.into(_db.historyEntries).insert(
          HistoryEntriesCompanion.insert(
            id: id,
            createdAt: createdAt?.toUtc() ?? now,
            updatedAt: now,
            establishmentId: establishmentId,
            kind: kind,
            title: title,
            body: body,
          ),
        );
    await _trimHistory(establishmentId);
    return id;
  }

  /// Оставляет только последние [historyLimit] записей, помечая остальные
  /// удалёнными.
  Future<void> _trimHistory(String establishmentId) async {
    final total = await (_db.selectOnly(_db.historyEntries)
          ..addColumns([_db.historyEntries.id.count()])
          ..where(_db.historyEntries.establishmentId.equals(establishmentId) &
              _db.historyEntries.deletedAt.isNull()))
        .map((row) => row.read(_db.historyEntries.id.count()) ?? 0)
        .getSingle();

    if (total <= historyLimit) return;

    final excess = total - historyLimit;
    final oldest = await (_db.select(_db.historyEntries)
          ..where((t) =>
              t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(excess))
        .get();

    if (oldest.isEmpty) return;
    final now = _now();
    await (_db.update(_db.historyEntries)
          ..where((t) => t.id.isIn(oldest.map((e) => e.id).toList())))
        .write(HistoryEntriesCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> clearHistory(String establishmentId, {String? kind}) async {
    final now = _now();
    await (_db.update(_db.historyEntries)
          ..where((t) {
            final base = t.establishmentId.equals(establishmentId) &
                t.deletedAt.isNull();
            return kind == null ? base : base & t.kind.equals(kind);
          }))
        .write(HistoryEntriesCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ── Закрытые смены ─────────────────────────────────────────────────────────

  Future<List<ShiftRow>> loadShifts(String establishmentId) {
    final query = _db.select(_db.shiftRecords)
      ..where((t) =>
          t.establishmentId.equals(establishmentId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.closedAt)]);
    return query.get();
  }

  Future<List<ShiftWriteoffRow>> loadWriteoffs(String shiftId) {
    final query = _db.select(_db.shiftWriteoffs)
      ..where((t) => t.shiftId.equals(shiftId));
    return query.get();
  }

  /// Записывает закрытую смену вместе со списаниями одной транзакцией.
  ///
  /// Возвращает идентификатор смены. Если смена с таким [id] уже есть,
  /// повторная запись не делает ничего: это защита от двойной отправки,
  /// та же, что и на сервере.
  Future<String> addShift({
    required String establishmentId,
    String? id,
    required DateTime closedAt,
    required List<String> staffNames,
    required int revenueMinor,
    int qrMinor = 0,
    int cardMinor = 0,
    int cashMinor = 0,
    int morningCashMinor = 0,
    int eveningCashMinor = 0,
    int inkassMinor = 0,
    Map<String, double> writeoffs = const {},
    Map<String, String> writeoffUnits = const {},
  }) async {
    final now = _now();
    final shiftId = id ?? Ids.newId();

    await _db.transaction(() async {
      final existing = await (_db.select(_db.shiftRecords)
            ..where((t) => t.id.equals(shiftId)))
          .getSingleOrNull();
      if (existing != null) return;

      await _db.into(_db.shiftRecords).insert(
            ShiftRecordsCompanion.insert(
              id: shiftId,
              createdAt: now,
              updatedAt: now,
              establishmentId: establishmentId,
              closedAt: closedAt.toUtc(),
              staffNames: Value(staffNames.join('\n')),
              revenueMinor: Value(revenueMinor),
              qrMinor: Value(qrMinor),
              cardMinor: Value(cardMinor),
              cashMinor: Value(cashMinor),
              morningCashMinor: Value(morningCashMinor),
              eveningCashMinor: Value(eveningCashMinor),
              inkassMinor: Value(inkassMinor),
            ),
          );

      if (writeoffs.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.shiftWriteoffs,
            writeoffs.entries
                .where((e) => e.value > 0)
                .map((e) => ShiftWriteoffsCompanion.insert(
                      id: Ids.newId(),
                      shiftId: shiftId,
                      productName: e.key,
                      quantity: e.value,
                      unit: Value(writeoffUnits[e.key] ?? 'шт'),
                      createdAt: now,
                    ))
                .toList(),
            mode: InsertMode.insertOrIgnore,
          );
        });
      }
    });

    return shiftId;
  }

  Future<void> clearShifts(String establishmentId) async {
    final now = _now();
    await (_db.update(_db.shiftRecords)
          ..where((t) =>
              t.establishmentId.equals(establishmentId) & t.deletedAt.isNull()))
        .write(ShiftRecordsCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ── Остатки ────────────────────────────────────────────────────────────────

  Future<Map<String, double>> loadStockLevels(String establishmentId) async {
    final rows = await (_db.select(_db.stockLevels)
          ..where((t) => t.establishmentId.equals(establishmentId)))
        .get();
    return {for (final row in rows) row.productId: row.remaining};
  }

  /// Записывает измеренные остатки.
  ///
  /// Более раннее измерение не затирает более позднее: устройство могло
  /// отправить старые данные позже новых. То же правило действует
  /// на сервере.
  Future<void> saveStockLevels({
    required String establishmentId,
    required Map<String, double> levels,
    DateTime? measuredAt,
  }) async {
    if (levels.isEmpty) return;
    final now = _now();
    final measured = measuredAt?.toUtc() ?? now;

    await _db.transaction(() async {
      for (final entry in levels.entries) {
        final existing = await (_db.select(_db.stockLevels)
              ..where((t) =>
                  t.establishmentId.equals(establishmentId) &
                  t.productId.equals(entry.key)))
            .getSingleOrNull();

        if (existing != null && existing.measuredAt.isAfter(measured)) continue;

        await _db.into(_db.stockLevels).insertOnConflictUpdate(
              StockLevelsCompanion.insert(
                establishmentId: establishmentId,
                productId: entry.key,
                remaining: entry.value,
                measuredAt: measured,
                updatedAt: now,
              ),
            );
      }
    });
  }
}
