import 'package:drift/drift.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';

/// Доступ к операциям: история документов, закрытые смены, остатки,
/// журнал движений товара, журнал изменений, напоминания, шаблоны.
///
/// Смены, движения товара и журнал изменений не редактируются — только
/// добавление и чтение.
class OperationsDao {
  OperationsDao(this._db);

  final AppDatabase _db;

  static DateTime _now() => DateTime.now().toUtc();

  /// Верхняя граница истории документов на заведение.
  static const historyLimit = 500;

  // ── История заявок и инвентаризаций ────────────────────────────────────────

  /// Записи от новых к старым.
  Future<List<HistoryEntryRow>> loadHistory(String venueId) {
    final query = _db.select(_db.historyEntries)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.get();
  }

  /// Записывает документ истории вместе с его строками одной транзакцией.
  Future<String> addHistoryEntry({
    required String venueId,
    String? id,
    required String kind,
    required String title,
    required String body,
    String? staffId,
    String? refId,
    String? attachmentPath,
    DateTime? createdAt,
    List<DocumentLineInput> lines = const [],
  }) async {
    final now = _now();
    final docId = id ?? Ids.newId();
    final created = createdAt?.toUtc() ?? now;
    await _db.transaction(() async {
      await _db.into(_db.historyEntries).insert(
            HistoryEntriesCompanion.insert(
              id: docId,
              createdAt: created,
              updatedAt: now,
              venueId: venueId,
              kind: kind,
              title: title,
              body: body,
              staffId: Value(staffId),
              refId: Value(refId),
              attachmentPath: Value(attachmentPath),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      if (lines.isNotEmpty) {
        await _db.batch((batch) => batch.insertAll(
              _db.documentLines,
              [
                for (final (i, l) in lines.indexed)
                  DocumentLinesCompanion.insert(
                    id: Ids.newId(),
                    venueId: venueId,
                    documentId: docId,
                    productId: Value(l.productId),
                    productName: l.productName,
                    unit: Value(l.unit),
                    ordered: Value(l.ordered),
                    quantity: l.quantity,
                    price: Value(l.price),
                    sortOrder: Value(i),
                    createdAt: created,
                  ),
              ],
            ));
      }
    });
    await _trimHistory(venueId);
    return docId;
  }

  /// Строки документа в исходном порядке.
  Future<List<DocumentLineRow>> loadDocumentLines(String documentId) {
    final query = _db.select(_db.documentLines)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return query.get();
  }

  /// Оставляет только последние [historyLimit] записей, остальные
  /// помечает удалёнными.
  Future<void> _trimHistory(String venueId) async {
    final total = await (_db.selectOnly(_db.historyEntries)
          ..addColumns([_db.historyEntries.id.count()])
          ..where(_db.historyEntries.venueId.equals(venueId) &
              _db.historyEntries.deletedAt.isNull()))
        .map((row) => row.read(_db.historyEntries.id.count()) ?? 0)
        .getSingle();
    if (total <= historyLimit) return;

    final oldest = await (_db.select(_db.historyEntries)
          ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(total - historyLimit))
        .get();
    if (oldest.isEmpty) return;
    final now = _now();
    await (_db.update(_db.historyEntries)
          ..where((t) => t.id.isIn(oldest.map((e) => e.id).toList())))
        .write(HistoryEntriesCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> clearHistory(String venueId, {String? kind}) async {
    final now = _now();
    await (_db.update(_db.historyEntries)
          ..where((t) {
            final base = t.venueId.equals(venueId) & t.deletedAt.isNull();
            return kind == null ? base : base & t.kind.equals(kind);
          }))
        .write(HistoryEntriesCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ── Закрытые смены ─────────────────────────────────────────────────────────

  Future<List<ShiftRow>> loadShifts(String venueId) {
    final query = _db.select(_db.shiftRecords)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
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
  /// Если смена с таким [id] уже есть, повторная запись ничего не делает —
  /// защита от двойной отправки.
  Future<String> addShift({
    required String venueId,
    String? id,
    required DateTime closedAt,
    required List<String> staffNames,
    String? closedByStaffId,
    required int revenueMinor,
    int qrMinor = 0,
    int cardMinor = 0,
    int cashMinor = 0,
    int morningCashMinor = 0,
    int eveningCashMinor = 0,
    int inkassMinor = 0,
    List<ShiftWriteoffInput> writeoffs = const [],
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
              venueId: venueId,
              closedAt: closedAt.toUtc(),
              staffNames: Value(staffNames.join('\n')),
              closedByStaffId: Value(closedByStaffId),
              revenueMinor: Value(revenueMinor),
              qrMinor: Value(qrMinor),
              cardMinor: Value(cardMinor),
              cashMinor: Value(cashMinor),
              morningCashMinor: Value(morningCashMinor),
              eveningCashMinor: Value(eveningCashMinor),
              inkassMinor: Value(inkassMinor),
            ),
          );

      final rows = writeoffs
          .where((w) => w.quantity > 0)
          .map((w) => ShiftWriteoffsCompanion.insert(
                id: Ids.newId(),
                shiftId: shiftId,
                productId: Value(w.productId),
                productName: w.productName,
                quantity: w.quantity,
                unit: Value(w.unit),
                createdAt: closedAt.toUtc(),
              ))
          .toList();
      if (rows.isNotEmpty) {
        await _db.batch((batch) => batch.insertAll(_db.shiftWriteoffs, rows));
      }
    });

    return shiftId;
  }

  Future<void> clearShifts(String venueId) async {
    final now = _now();
    await (_db.update(_db.shiftRecords)
          ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull()))
        .write(ShiftRecordsCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ── Последние измеренные остатки ───────────────────────────────────────────

  Future<Map<String, double>> loadStockLevels(String venueId) async {
    final rows = await (_db.select(_db.stockLevels)
          ..where((t) => t.venueId.equals(venueId)))
        .get();
    return {for (final row in rows) row.productId: row.remaining};
  }

  /// Записывает измеренные остатки. Более раннее измерение не затирает
  /// более позднее: устройство могло прислать старые данные позже новых.
  Future<void> saveStockLevels({
    required String venueId,
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
                  t.venueId.equals(venueId) & t.productId.equals(entry.key)))
            .getSingleOrNull();
        if (existing != null && existing.measuredAt.isAfter(measured)) continue;

        await _db.into(_db.stockLevels).insertOnConflictUpdate(
              StockLevelsCompanion.insert(
                venueId: venueId,
                productId: entry.key,
                remaining: entry.value,
                measuredAt: measured,
                updatedAt: now,
              ),
            );
      }
    });
  }

  // ── Журнал движений товара ─────────────────────────────────────────────────

  /// Добавляет движения одной транзакцией. Изменять и удалять движения
  /// нельзя — ошибку исправляют новой строкой kind='adjustment'.
  Future<void> addMovements(List<StockMovementInput> movements) async {
    if (movements.isEmpty) return;
    final now = _now();
    await _db.batch((batch) {
      batch.insertAll(
        _db.stockMovements,
        movements
            .map((m) => StockMovementsCompanion.insert(
                  id: m.id ?? Ids.newId(),
                  venueId: m.venueId,
                  productId: m.productId,
                  kind: m.kind,
                  quantity: m.quantity,
                  occurredAt: m.occurredAt.toUtc(),
                  sourceType: Value(m.sourceType),
                  sourceId: Value(m.sourceId),
                  staffId: Value(m.staffId),
                  note: Value(m.note),
                  createdAt: now,
                ))
            .toList(),
        // Повторная отправка той же строки (тот же id) гасится.
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// Движения заведения за период [from, to), от старых к новым.
  Future<List<StockMovementRow>> loadMovements(
    String venueId, {
    DateTime? from,
    DateTime? to,
    String? productId,
  }) {
    final query = _db.select(_db.stockMovements)
      ..where((t) {
        var cond = t.venueId.equals(venueId);
        if (from != null) {
          cond = cond & t.occurredAt.isBiggerOrEqualValue(from.toUtc());
        }
        if (to != null) {
          cond = cond & t.occurredAt.isSmallerThanValue(to.toUtc());
        }
        if (productId != null) cond = cond & t.productId.equals(productId);
        return cond;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.occurredAt)]);
    return query.get();
  }

  // ── Журнал изменений ───────────────────────────────────────────────────────

  Future<void> addAudit({
    required String venueId,
    String? staffId,
    required String entity,
    required String entityId,
    required String action,
    String? beforeJson,
    String? afterJson,
    String? reason,
  }) async {
    await _db.into(_db.auditLog).insert(
          AuditLogCompanion.insert(
            id: Ids.newId(),
            venueId: venueId,
            at: _now(),
            staffId: Value(staffId),
            entity: entity,
            entityId: entityId,
            action: action,
            beforeJson: Value(beforeJson),
            afterJson: Value(afterJson),
            reason: Value(reason),
          ),
        );
  }

  Future<List<AuditLogRow>> loadAudit(String venueId, {String? entityId}) {
    final query = _db.select(_db.auditLog)
      ..where((t) {
        final base = t.venueId.equals(venueId);
        return entityId == null ? base : base & t.entityId.equals(entityId);
      })
      ..orderBy(
          [(t) => OrderingTerm(expression: t.at, mode: OrderingMode.desc)]);
    return query.get();
  }

  // ── Напоминания ────────────────────────────────────────────────────────────

  Future<List<ReminderRow>> loadReminders(String venueId) {
    final query = _db.select(_db.reminders)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.get();
  }

  // ── Шаблон PDF ─────────────────────────────────────────────────────────────

  Future<ExportTemplateRow?> loadTemplate(String venueId) {
    final query = _db.select(_db.exportTemplates)
      ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }
}

/// Строка документа (заявки, приёмки, инвентаризации).
class DocumentLineInput {
  final String? productId;
  final String productName;
  final String unit;
  final double? ordered;
  final double quantity;
  final double? price;

  const DocumentLineInput({
    this.productId,
    required this.productName,
    this.unit = 'шт',
    this.ordered,
    required this.quantity,
    this.price,
  });
}

/// Строка списания при закрытии смены.
class ShiftWriteoffInput {
  final String? productId;
  final String productName;
  final double quantity;
  final String unit;

  const ShiftWriteoffInput({
    this.productId,
    required this.productName,
    required this.quantity,
    this.unit = 'шт',
  });
}

/// Движение товара для записи в журнал.
class StockMovementInput {
  final String? id;
  final String venueId;
  final String productId;
  final String kind;
  final double quantity;
  final DateTime occurredAt;
  final String? sourceType;
  final String? sourceId;
  final String? staffId;
  final String? note;

  const StockMovementInput({
    this.id,
    required this.venueId,
    required this.productId,
    required this.kind,
    required this.quantity,
    required this.occurredAt,
    this.sourceType,
    this.sourceId,
    this.staffId,
    this.note,
  });
}
