/// Сохранение пересчёта. Раньше история, остатки и журнал склада писались
/// только по кнопке PDF: «Копировать» и «Поделиться» отправляли отчёт,
/// а склад о пересчёте не знал.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';
import 'package:horeca_app/features/supply/presentation/stock_levels_bridge.dart';

/// Последний сохранённый пересчёт. Тот же объект состояния — тот же отчёт:
/// вторая кнопка его не дублирует. Правка отчёта создаёт новое состояние,
/// и он сохраняется заново.
final savedInventoryProvider = StateProvider<InventoryState?>((ref) => null);

List<StockMove> inventoryCountMoves(InventoryState state, DateTime at) {
  final batch = at.millisecondsSinceEpoch.toString();
  return [
    for (final item in state.items)
      StockMove(
        id: 'count-$batch-${item.productId}',
        at: at,
        productKey: item.productId,
        name: item.productName,
        unit: item.unit.isEmpty ? 'шт' : item.unit,
        kind: StockMoveKind.count,
        qty: item.remaining,
      ),
  ];
}

/// Пишет пересчёт в историю, текущие остатки и журнал склада один раз на
/// отчёт. Возвращает true, если записал сейчас.
bool saveInventoryOnce(
  ProviderRead read, {
  required InventoryState state,
  required String title,
  required String text,
  DateTime? now,
}) {
  if (state.items.isEmpty) return false;
  if (identical(read(savedInventoryProvider), state)) return false;
  final at = now ?? DateTime.now();
  read(historyRepositoryProvider).add(HistoryEntry(
    id: at.millisecondsSinceEpoch.toString(),
    type: HistoryType.inventory,
    title: title,
    text: text,
    createdAt: at,
  ));
  read(stockLevelsRepositoryProvider.notifier).updateLevels({
    for (final item in state.items) item.productId: item.remaining,
  });
  read(supplyRepositoryProvider.notifier)
      .recordCounts(at: at, counts: inventoryCountMoves(state, at));
  applyComputedStockWith(read);
  read(savedInventoryProvider.notifier).state = state;
  return true;
}
