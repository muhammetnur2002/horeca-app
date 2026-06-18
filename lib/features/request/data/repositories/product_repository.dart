import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

class Product {
  final String id;
  final String name;
  final String unit;
  final String categoryId;
  Product({required this.id, required this.name, required this.unit, required this.categoryId});
}

// Провайдер продуктов, отфильтрованных по категории
final productsProvider = Provider.family<List<Product>, String>((ref, categoryId) {
  final allProducts = ref.watch(settingsRepositoryProvider).products;
  return allProducts
      .where((p) => p.categoryId == categoryId)
      .map((p) => Product(id: p.id, name: p.name, unit: p.unit, categoryId: p.categoryId))
      .toList();
});