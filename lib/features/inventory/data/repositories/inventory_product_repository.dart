import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';

class InventoryProduct {
  final String id;
  final String name;
  final String unit;
  final String departmentId;

  InventoryProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.departmentId,
  });
}

final inventoryProductsProvider = Provider.family<List<InventoryProduct>, String>(
  (ref, departmentId) {
    final allProducts = ref.watch(settingsRepositoryProvider).products;
    final allCategories = ref.watch(settingsRepositoryProvider).categories;

    if (departmentId == 'all') {
      // Возвращаем все товары, помечая их departmentId как 'all'
      return allProducts
          .map((p) {
            final cat = allCategories.firstWhere(
              (c) => c.id == p.categoryId,
              orElse: () => CategoryModel(id: '', name: '', departmentId: ''),
            );
            return InventoryProduct(
              id: p.id,
              name: p.name,
              unit: p.unit,
              departmentId: 'all', // или cat.departmentId, но для общего отчёта не важно
            );
          })
          .toList();
    }

    return allProducts
        .where((p) {
          final cat = allCategories.firstWhere(
            (c) => c.id == p.categoryId,
            orElse: () => CategoryModel(id: '', name: '', departmentId: ''),
          );
          return cat.departmentId == departmentId;
        })
        .map((p) => InventoryProduct(
              id: p.id,
              name: p.name,
              unit: p.unit,
              departmentId: departmentId,
            ))
        .toList();
  },
);