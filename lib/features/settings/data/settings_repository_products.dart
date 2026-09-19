/// CRUD-методы для товаров — extension на SettingsRepository. Вынесены из
/// settings_repository.dart, чтобы не раздувать его; работают через
/// публичные data/applyUpdate() (state из StateNotifier — protected,
/// extension-методы не могут его использовать напрямую, т.к. extension не
/// является подклассом).
library;

import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';

extension SettingsRepositoryProducts on SettingsRepository {
  bool isDuplicateProduct(String name, String categoryId) {
    return data.products.any((p) =>
        p.categoryId == categoryId &&
        p.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  void addProduct(String name, String unit, String categoryId,
      {String? inventoryUnit}) {
    addProductWithId(DateTime.now().millisecondsSinceEpoch.toString(), name,
        unit, categoryId,
        inventoryUnit: inventoryUnit);
  }

  /// Вариант addProduct с явным id — см. комментарий у addCategoryWithId:
  /// нужен для массового импорта, где id на основе времени может
  /// коллизировать при добавлении многих товаров подряд в одном цикле.
  void addProductWithId(
      String id, String name, String unit, String categoryId,
      {String? inventoryUnit}) {
    final p = ProductModel(
        id: id,
        name: name,
        unit: unit,
        inventoryUnit: inventoryUnit ?? unit,
        categoryId: categoryId);
    applyUpdate((s) => s.copyWith(products: [...s.products, p]));
  }

  void updateProduct(String id, String newName, String newUnit,
      {String? newCategoryId, String? newInventoryUnit}) {
    applyUpdate((s) => s.copyWith(
            products: s.products.map((p) {
          if (p.id == id) {
            return ProductModel(
                id: p.id,
                name: newName,
                unit: newUnit,
                inventoryUnit: newInventoryUnit ?? p.inventoryUnit,
                categoryId: newCategoryId ?? p.categoryId);
          }
          return p;
        }).toList()));
  }

  void deleteProduct(String id) {
    applyUpdate((s) =>
        s.copyWith(products: s.products.where((p) => p.id != id).toList()));
  }

  void setProductMinStock(String id, double? minStock) {
    applyUpdate((s) => s.copyWith(
          products: s.products.map((p) {
            if (p.id == id) {
              return ProductModel(
                id: p.id,
                name: p.name,
                unit: p.unit,
                inventoryUnit: p.inventoryUnit,
                categoryId: p.categoryId,
                minStock: minStock,
              );
            }
            return p;
          }).toList(),
        ));
  }

  void bulkAddProducts(
      List<String> names, String defaultUnit, String categoryId,
      {String? defaultInventoryUnit}) {
    final newProds = names
        .map((name) => ProductModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + name,
            name: name,
            unit: defaultUnit,
            inventoryUnit: defaultInventoryUnit ?? defaultUnit,
            categoryId: categoryId))
        .toList();
    applyUpdate((s) => s.copyWith(products: [...s.products, ...newProds]));
  }
}
