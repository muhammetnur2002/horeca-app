/// Товарный учёт заведения: запись движений (стартовые остатки,
/// инвентаризация, приёмка поставки, списания) и расчёт итогов.
///
/// Движения пишутся в журнал StockMovements, который нельзя править —
/// только дополнять. Каждый документ (приёмка, стартовые остатки)
/// дополнительно попадает в журнал действий с именем сотрудника.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/stock/domain/receipt_line.dart';
import 'package:horeca_app/features/stock/domain/stock_ledger.dart';

export 'package:horeca_app/features/stock/domain/receipt_line.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Кто сейчас работает с приложением: личный PIN или общий.
class Actor {
  final String? staffId;
  final String? name;
  const Actor({this.staffId, this.name});

  factory Actor.of(AuthState auth) =>
      Actor(staffId: auth.staffId, name: auth.userName);
}

class StockRepository {
  final OperationsDao _dao;
  final String _venueId;

  StockRepository(this._dao, this._venueId);

  // ── Замеры ────────────────────────────────────────────────────────────────

  /// Результат инвентаризации: фактические остатки (в единицах
  /// инвентаризации). [baseline] — стартовые остатки (точка отсчёта учёта).
  Future<void> recordCount(
    Map<String, double> remaining, {
    bool baseline = false,
    String? documentId,
    Actor actor = const Actor(),
    DateTime? at,
  }) async {
    if (remaining.isEmpty) return;
    final when = at ?? DateTime.now();
    final kind = baseline ? MovementKind.baseline : MovementKind.count;
    await _dao.addMovements([
      for (final e in remaining.entries)
        StockMovementInput(
          venueId: _venueId,
          productId: e.key,
          kind: kind,
          quantity: e.value,
          occurredAt: when,
          sourceType: baseline ? 'baseline' : 'inventory',
          sourceId: documentId,
          staffId: actor.staffId,
        ),
    ]);
    if (baseline) {
      await _dao.addAudit(
        venueId: _venueId,
        staffId: actor.staffId,
        entity: 'baseline',
        entityId: documentId ?? Ids.newId(),
        action: 'create',
        afterJson: jsonEncode({
          'products': remaining.length,
          if (actor.name != null) 'by': actor.name,
        }),
      );
    }
  }

  // ── Приёмка поставки ──────────────────────────────────────────────────────

  /// Записывает приёмку: документ в истории со строками «заказано/пришло»,
  /// приход в журнал движений (в единицах инвентаризации) и запись
  /// в журнал действий. Возвращает id документа.
  Future<String> recordReceipt({
    required List<ReceiptLine> lines,
    required String title,
    required String text,
    String? requestId,
    String? photoPath,
    Actor actor = const Actor(),
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();
    final id = await _dao.addHistoryEntry(
      venueId: _venueId,
      kind: 'receipt',
      title: title,
      body: text,
      staffId: actor.staffId,
      refId: requestId,
      attachmentPath: photoPath,
      createdAt: when,
      lines: [
        for (final l in lines)
          DocumentLineInput(
            productId: l.productId,
            productName: l.productName,
            unit: l.unit,
            ordered: l.ordered,
            quantity: l.received,
            price: l.price,
          ),
      ],
    );
    await _dao.addMovements([
      for (final l in lines)
        // Строки без товара каталога в остатки не идут.
        if (l.received != 0 && l.productId != null)
          StockMovementInput(
            venueId: _venueId,
            productId: l.productId!,
            kind: MovementKind.receipt,
            quantity: l.received * l.unitFactor,
            occurredAt: when,
            sourceType: 'receipt',
            sourceId: id,
            staffId: actor.staffId,
          ),
    ]);
    await _dao.addAudit(
      venueId: _venueId,
      staffId: actor.staffId,
      entity: 'receipt',
      entityId: id,
      action: 'create',
      afterJson: jsonEncode({
        'lines': lines.length,
        'received': lines.where((l) => l.received > 0).length,
        'short': lines.where((l) => l.shortage > 0).length,
        if (requestId != null) 'request': requestId,
        if (photoPath != null) 'photo': true,
        if (lines.any((l) => l.productId == null))
          'unmatched': lines.where((l) => l.productId == null).length,
        if (actor.name != null) 'by': actor.name,
      }),
    );
    return id;
  }

  // ── Списания при закрытии смены ───────────────────────────────────────────

  Future<void> recordWriteoffs(
    Map<String, double> byProductId, {
    required String shiftId,
    Actor actor = const Actor(),
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();
    await _dao.addMovements([
      for (final e in byProductId.entries)
        if (e.value > 0)
          StockMovementInput(
            // id от смены и товара: повторное закрытие той же смены
            // не задвоит списание.
            id: 'wo-$shiftId-${e.key}',
            venueId: _venueId,
            productId: e.key,
            kind: MovementKind.writeoff,
            quantity: -e.value,
            occurredAt: when,
            sourceType: 'shift',
            sourceId: shiftId,
            staffId: actor.staffId,
          ),
    ]);
  }

  // ── Чтение ────────────────────────────────────────────────────────────────

  Future<Map<String, LedgerLine>> ledger({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _dao.loadMovements(_venueId, to: to);
    return StockLedger.compute(
      rows.map((r) => Movement(
            productId: r.productId,
            kind: r.kind,
            quantity: r.quantity,
            occurredAt: r.occurredAt.toLocal(),
          )),
      from: from,
      to: to,
    );
  }

  /// Были ли уже стартовые остатки или инвентаризации.
  Future<bool> hasAnyCount() async {
    final rows = await _dao.loadMovements(_venueId);
    return rows.any((r) => MovementKind.isAbsolute(r.kind));
  }

  /// Документы истории заданного вида, от новых к старым.
  Future<List<HistoryEntryRow>> documents(String kind) async =>
      (await _dao.loadHistory(_venueId)).where((r) => r.kind == kind).toList();

  Future<List<DocumentLineRow>> lines(String documentId) =>
      _dao.loadDocumentLines(documentId);

  Future<List<AuditLogRow>> audit() => _dao.loadAudit(_venueId);
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(
    ref.watch(operationsDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});

/// Счётчик изменений учёта: экраны учёта перечитывают данные, когда он
/// растёт (после приёмки, инвентаризации, стартовых остатков).
final stockRevisionProvider = StateProvider<int>((ref) => 0);
