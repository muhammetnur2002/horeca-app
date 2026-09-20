/// Панель массового редактирования выбранных товаров (смена отдела,
/// категории, ед. изм. заявки/инвентаризации). Вынесена из products_tab.dart,
/// чтобы не раздувать его build().
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_products.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_batch_dialogs.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_widgets.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

/// Возвращает панель массового редактирования, если есть выбранные товары
/// и включён режим выбора, иначе null (и тогда её не нужно показывать).
Widget? buildProductBatchEditPanel({
  required BuildContext context,
  required SettingsRepository repo,
  required List<DepartmentModel> departments,
  required List<CategoryModel> categories,
  required List<ProductModel> products,
  required Set<String> selectedIds,
  required bool isDark,
  required bool selectMode,
  required StateSetter setState,
  required VoidCallback onExitSelectMode,
}) {
  if (!selectMode || selectedIds.isEmpty) return null;

  return ProductBatchEditPanel(
    selectedCount: selectedIds.length,
    isDark: isDark,
    onChangeDepartment: () => changeProductsDepartmentAndCategory(
      context: context,
      repo: repo,
      departments: departments,
      allCategories: categories,
      products: products,
      selectedIds: selectedIds,
      setState: setState,
      onExitSelectMode: onExitSelectMode,
    ),
    onChangeCategory: () {
      final catNames = categories.map((c) => c.name).toSet().toList();
      showBatchChangeProductsDialog(
        context: context,
        repo: repo,
        ids: selectedIds.toList(),
        title: 'Категория',
        options: catNames,
        onApply: (repo, id, newValue) {
          final product = products.firstWhere((p) => p.id == id);
          repo.updateProduct(
            id,
            product.name,
            newValue,
            newCategoryId: product.categoryId,
            newInventoryUnit: product.inventoryUnit,
          );
        },
      );
    },
    onChangeOrderUnit: () {
      const units = ['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'];
      showBatchChangeProductsDialog(
        context: context,
        repo: repo,
        ids: selectedIds.toList(),
        title: 'Ед. изм. (заявка)',
        options: units,
        onApply: (repo, id, newValue) {
          final product = products.firstWhere((p) => p.id == id);
          repo.updateProduct(id, product.name, newValue,
              newCategoryId: product.categoryId,
              newInventoryUnit: product.inventoryUnit);
        },
      );
    },
    onChangeInventoryUnit: () {
      const units = ['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'];
      showBatchChangeProductsDialog(
        context: context,
        repo: repo,
        ids: selectedIds.toList(),
        title: 'Ед. изм. (инвент.)',
        options: units,
        onApply: (repo, id, newValue) {
          final product = products.firstWhere((p) => p.id == id);
          repo.updateProduct(
            id,
            product.name,
            product.unit,
            newCategoryId: product.categoryId,
            newInventoryUnit: newValue,
          );
        },
      );
    },
  );
}
