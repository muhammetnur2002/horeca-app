/// Список товаров экрана "Товары" (карточки с ценой/остатком) и его пустое
/// состояние. Вынесен из products_tab.dart, чтобы не раздувать его build().
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_widgets.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

/// Прокручиваемый список товаров или заглушка "Нет товаров".
Widget buildProductsListView({
  required List<ProductModel> filtered,
  required List<CategoryModel> categories,
  required List<DepartmentModel> departments,
  required bool isDark,
  required bool selectMode,
  required Set<String> selectedIds,
  required void Function(ProductModel p) onSetMinStock,
  required void Function(ProductModel p) onDelete,
  required void Function(ProductModel p) onEdit,
  required void Function(String id, bool? value) onSelectChanged,
  required void Function(String id) onToggleSelect,
}) {
  return Expanded(
    child: filtered.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      size: 36, color: AppColors.muted.withOpacity(0.5)),
                ),
                const SizedBox(height: 16),
                Text('Нет товаров',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            itemCount: filtered.length,
            itemBuilder: (_, index) {
              final p = filtered[index];
              final cat = categories.firstWhere(
                (c) => c.id == p.categoryId,
                orElse: () => CategoryModel(
                    id: '', name: 'Без категории', departmentId: ''),
              );
              final dept = departments.firstWhere(
                (d) => d.id == cat.departmentId,
                orElse: () =>
                    DepartmentModel(id: '', name: 'Неизвестно', icon: Icons.help),
              );
              final isSelected = selectedIds.contains(p.id);
              return ProductItemCard(
                p: p,
                catName: cat.name,
                deptName: dept.name,
                isDark: isDark,
                isSelected: isSelected,
                selectMode: selectMode,
                onSetMinStock: () => onSetMinStock(p),
                onSelect: (v) => onSelectChanged(p.id, v),
                onDelete: () => onDelete(p),
                onTap: selectMode
                    ? () => onToggleSelect(p.id)
                    : () => onEdit(p),
              );
            },
          ),
  );
}
