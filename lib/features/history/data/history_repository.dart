import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// История заявок и инвентаризаций заведения. Записи хранятся в базе,
/// состояние — список от новых к старым.
class HistoryRepository extends StateNotifier<List<HistoryEntry>> {
  final OperationsDao _dao;
  final String _venueId;

  HistoryRepository(this._dao, this._venueId) : super(const []) {
    _ready = _load();
  }

  late final Future<void> _ready;

  /// Завершается, когда данные загружены из базы.
  Future<void> get ready => _ready;

  Future<void> _load() async {
    final rows = await _dao.loadHistory(_venueId);
    if (!mounted) return;
    // Приёмки поставок тоже лежат в истории документов, но показываются
    // в разделе «Учёт товара», а не на экране истории.
    state = rows
        .where((r) => r.kind == 'request' || r.kind == 'inventory')
        .map((r) => HistoryEntry(
              id: r.id,
              type: r.kind == 'inventory'
                  ? HistoryType.inventory
                  : HistoryType.request,
              title: r.title,
              text: r.body,
              createdAt: r.createdAt.toLocal(),
            ))
        .toList();
  }

  List<HistoryEntry> getAll() => List.unmodifiable(state);

  /// Добавляет документ. [lines] — его строки (что заказали / сколько
  /// насчитали), нужны для сверки поставки с заявкой.
  Future<void> add(
    HistoryEntry entry, {
    List<DocumentLineInput> lines = const [],
    String? staffId,
  }) {
    state = [entry, ...state];
    return _dao.addHistoryEntry(
      venueId: _venueId,
      id: entry.id,
      kind: entry.type == HistoryType.inventory ? 'inventory' : 'request',
      title: entry.title,
      body: entry.text,
      staffId: staffId,
      createdAt: entry.createdAt,
      lines: lines,
    );
  }

  void clear() {
    state = const [];
    _dao.clearHistory(_venueId);
  }

  void clearByType(HistoryType type, {String? staffId}) {
    state = state.where((e) => e.type != type).toList();
    final kind = type == HistoryType.inventory ? 'inventory' : 'request';
    _dao.clearHistory(_venueId, kind: kind);
    // Очистка истории — заметное действие, оставляем след в журнале.
    _dao.addAudit(
      venueId: _venueId,
      staffId: staffId,
      entity: 'history',
      entityId: kind,
      action: 'delete',
      afterJson: '{"kind":"${type == HistoryType.inventory ? 'инвентаризации' : 'заявки'}"}',
    );
  }
}

final historyRepositoryProvider =
    StateNotifierProvider<HistoryRepository, List<HistoryEntry>>((ref) {
  return HistoryRepository(
    ref.watch(operationsDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});

/// Записи от новых к старым.
final historyEntriesProvider = Provider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider);
});
