import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';
import 'package:horeca_app/shared/models/product_model.dart';

/// Чтение провайдера: `ref.read` экрана или `container.read` теста.
typedef ProviderRead = T Function<T>(ProviderListenable<T> provider);

/// Переписывает остатки каталога из журнала движений.
/// Товары без движений не трогает: старый подсчёт остаётся.
void applyComputedStock(WidgetRef ref) => applyComputedStockWith(ref.read);

void applyComputedStockWith(ProviderRead read) {
  final products = read(settingsRepositoryProvider).products;
  final moves = read(supplyRepositoryProvider).moves;
  if (products.isEmpty || moves.isEmpty) return;
  final now = DateTime.now();
  final levels = <String, double>{};
  for (final product in products) {
    final named = nameProductKey(product.name);
    final own = moves
        .where((m) => m.productKey == product.id || m.productKey == named)
        .toList();
    if (own.isEmpty) continue;
    levels[product.id] = balanceAt(own, now);
  }
  if (levels.isEmpty) return;
  read(stockLevelsRepositoryProvider.notifier).updateLevels(levels);
}

String stockKeyFor(
  Iterable<ProductModel> products,
  String name, {
  String productId = '',
}) {
  if (productId.isNotEmpty && !productId.startsWith('name:')) return productId;
  final named = nameProductKey(name);
  for (final product in products) {
    if (nameProductKey(product.name) == named) return product.id;
  }
  return named;
}

Map<String, double> minimumsByKey(Iterable<ProductModel> products) {
  final out = <String, double>{};
  for (final product in products) {
    final minStock = product.minStock;
    if (minStock == null || minStock <= 0) continue;
    out[product.id] = minStock;
    out[nameProductKey(product.name)] = minStock;
  }
  return out;
}

/// Единица товара для склада: единица инвентаризации, иначе основная.
/// Товар не из каталога — пусто, журнал запишет «шт».
String stockUnitFor(Iterable<ProductModel> products, String name) {
  final named = nameProductKey(name);
  for (final product in products) {
    if (nameProductKey(product.name) == named) return product.inventoryUnit;
  }
  return '';
}
