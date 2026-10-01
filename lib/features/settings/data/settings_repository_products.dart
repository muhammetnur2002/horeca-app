/// CRUD-методы для товаров — extension на SettingsRepository. Каждое
/// изменение применяется к состоянию в памяти и записывается в базу.
library;

import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';

extension SettingsRepositoryProducts on SettingsRepository {
  bool isDuplicateProduct(String name, String categoryId) {
    return data.products.any((p) =>
        p.categoryId == categoryId &&
        p.name.trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// [sortOrder] передаётся только при добавлении — новые товары
  /// встают в конец; при изменении порядок сохраняется.
  void _save(ProductModel p, {int? sortOrder}) {
    dao.upsertProduct(
      venueId: venueId,
      id: p.id,
      name: p.name,
      unit: p.unit,
      inventoryUnit: p.inventoryUnit,
      categoryId: p.categoryId.isEmpty ? null : p.categoryId,
      minStock: p.minStock,
      iikoProductId: p.iikoProductId,
      sortOrder: sortOrder,
    );
  }

  void addProduct(String name, String unit, String categoryId,
      {String? inventoryUnit}) {
    addProductWithId(Ids.newId(), name, unit, categoryId,
        inventoryUnit: inventoryUnit);
  }

  void addProductWithId(
      String id, String name, String unit, String categoryId,
      {String? inventoryUnit, String? iikoProductId}) {
    final p = ProductModel(
        id: id,
        name: name,
        unit: unit,
        inventoryUnit: inventoryUnit ?? unit,
        categoryId: categoryId,
        iikoProductId: iikoProductId);
    applyUpdate((s) => s.copyWith(products: [...s.products, p]));
    _save(p, sortOrder: data.products.length - 1);
  }

  void updateProduct(String id, String newName, String newUnit,
      {String? newCategoryId, String? newInventoryUnit}) {
    ProductModel? updated;
    applyUpdate((s) => s.copyWith(
            products: s.products.map((p) {
          if (p.id == id) {
            return updated = ProductModel(
                id: p.id,
                name: newName,
                unit: newUnit,
                inventoryUnit: newInventoryUnit ?? p.inventoryUnit,
                categoryId: newCategoryId ?? p.categoryId,
                minStock: p.minStock,
                iikoProductId: p.iikoProductId);
          }
          return p;
        }).toList()));
    if (updated != null) _save(updated!);
  }

  void deleteProduct(String id) {
    applyUpdate((s) =>
        s.copyWith(products: s.products.where((p) => p.id != id).toList()));
    dao.deleteProduct(id);
  }

  void setProductMinStock(String id, double? minStock) {
    ProductModel? updated;
    applyUpdate((s) => s.copyWith(
          products: s.products.map((p) {
            if (p.id == id) {
              return updated = ProductModel(
                id: p.id,
                name: p.name,
                unit: p.unit,
                inventoryUnit: p.inventoryUnit,
                categoryId: p.categoryId,
                minStock: minStock,
                iikoProductId: p.iikoProductId,
              );
            }
            return p;
          }).toList(),
        ));
    if (updated != null) _save(updated!);
  }

  void bulkAddProducts(
      List<String> names, String defaultUnit, String categoryId,
      {String? defaultInventoryUnit}) {
    final newProds = names
        .map((name) => ProductModel(
            id: Ids.newId(),
            name: name,
            unit: defaultUnit,
            inventoryUnit: defaultInventoryUnit ?? defaultUnit,
            categoryId: categoryId))
        .toList();
    final start = data.products.length;
    applyUpdate((s) => s.copyWith(products: [...s.products, ...newProds]));
    for (var i = 0; i < newProds.length; i++) {
      _save(newProds[i], sortOrder: start + i);
    }
  }
}
