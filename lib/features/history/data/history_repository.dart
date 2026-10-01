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
    state = rows
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

  void add(HistoryEntry entry) {
    state = [entry, ...state];
    _dao.addHistoryEntry(
      venueId: _venueId,
      kind: entry.type == HistoryType.inventory ? 'inventory' : 'request',
      title: entry.title,
      body: entry.text,
      createdAt: entry.createdAt,
    );
  }

  void clear() {
    state = const [];
    _dao.clearHistory(_venueId);
  }

  void clearByType(HistoryType type) {
    state = state.where((e) => e.type != type).toList();
    _dao.clearHistory(_venueId,
        kind: type == HistoryType.inventory ? 'inventory' : 'request');
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
