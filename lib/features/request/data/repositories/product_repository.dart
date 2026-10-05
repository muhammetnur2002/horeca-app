import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

class Product {
  final String id;
  final String name;
  final String unit;
  final String categoryId;

  /// Минимальный остаток — чтобы подсветить товар, который заканчивается.
  final double? minStock;

  /// Единица, в которой считается остаток (может отличаться от единицы заявки).
  final String? inventoryUnit;
  Product({required this.id, required this.name, required this.unit, required this.categoryId, this.minStock, this.inventoryUnit});
}

// Провайдер продуктов, отфильтрованных по категории
final productsProvider = Provider.family<List<Product>, String>((ref, categoryId) {
  final allProducts = ref.watch(settingsRepositoryProvider).products;
  return allProducts
      .where((p) => p.categoryId == categoryId)
      .map((p) => Product(id: p.id, name: p.name, unit: p.unit, categoryId: p.categoryId, minStock: p.minStock, inventoryUnit: p.inventoryUnit))
      .toList();
});
