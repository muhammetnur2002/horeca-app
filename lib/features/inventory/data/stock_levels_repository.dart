import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Последние измеренные остатки заведения (id товара → количество).
/// Хранятся в базе отдельно для каждого заведения.
class StockLevelsRepository extends StateNotifier<Map<String, double>> {
  final OperationsDao _dao;
  final String _venueId;

  StockLevelsRepository(this._dao, this._venueId) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final levels = await _dao.loadStockLevels(_venueId);
    if (!mounted) return;
    state = levels;
  }

  void updateLevels(Map<String, double> levels) {
    state = {...state, ...levels};
    _dao.saveStockLevels(venueId: _venueId, levels: levels);
  }

  /// Сдвигает известные остатки на [deltas] (приход +, списание −),
  /// чтобы баннер «заканчивается» учитывал поставку без новой
  /// инвентаризации. Товары, остаток которых ещё не измеряли, не трогаем.
  void applyDeltas(Map<String, double> deltas) {
    final changed = <String, double>{
      for (final e in deltas.entries)
        if (state[e.key] != null)
          e.key: (state[e.key]! + e.value).clamp(0, double.infinity).toDouble(),
    };
    if (changed.isNotEmpty) updateLevels(changed);
  }

  double? getLevel(String productId) => state[productId];
}

final stockLevelsRepositoryProvider =
    StateNotifierProvider<StockLevelsRepository, Map<String, double>>((ref) {
  return StockLevelsRepository(
    ref.watch(operationsDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});
