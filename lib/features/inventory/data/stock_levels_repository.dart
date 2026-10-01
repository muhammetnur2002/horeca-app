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

  double? getLevel(String productId) => state[productId];
}

final stockLevelsRepositoryProvider =
    StateNotifierProvider<StockLevelsRepository, Map<String, double>>((ref) {
  return StockLevelsRepository(
    ref.watch(operationsDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});
