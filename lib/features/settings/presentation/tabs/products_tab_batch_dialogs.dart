/// Диалоги массовых операций экрана "Товары": выбор из списка (низовой
/// bottom sheet), массовая смена отдела/категории/поля, массовое добавление
/// товаров по списку. Вынесены из products_tab_dialogs.dart — там остаются
/// диалоги для одного товара (мин. остаток, удаление, добавление/редактирование).
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_products.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

const _kUnits = ['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'];

/// Нижний лист с выбором одного варианта из списка (используется для выбора
/// отдела/категории при массовом изменении).
Future<String?> showProductOptionsDialog(
    BuildContext context, String title, List<String> options) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard.withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ...options.map((o) => ListTile(
                    title: Text(o),
                    onTap: () => Navigator.pop(context, o),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Массовая смена отдела+категории у выбранных товаров (кнопка "Отдел" в
/// панели массового редактирования).
Future<void> changeProductsDepartmentAndCategory({
  required BuildContext context,
  required SettingsRepository repo,
  required List<DepartmentModel> departments,
  required List<CategoryModel> allCategories,
  required List<ProductModel> products,
  required Set<String> selectedIds,
  required StateSetter setState,
  required VoidCallback onExitSelectMode,
}) async {
  if (selectedIds.isEmpty) return;
  final deptNames = departments.map((d) => d.name).toList();
  final deptName = await showProductOptionsDialog(context, 'Выберите отдел', deptNames);
  if (deptName == null) return;
  if (!context.mounted) return;
  final dept = departments.firstWhere((d) => d.name == deptName);
  final catsInDept =
      allCategories.where((c) => c.departmentId == dept.id).toList();
  if (catsInDept.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('В этом отделе нет категорий')));
    return;
  }
  final catNames = catsInDept.map((c) => c.name).toList();
  final catName = await showProductOptionsDialog(context, 'Выберите категорию', catNames);
  if (catName == null) return;
  if (!context.mounted) return;
  final cat = catsInDept.firstWhere((c) => c.name == catName);
  for (final id in selectedIds.toList()) {
    final product = products.firstWhere((p) => p.id == id);
    repo.updateProduct(id, product.name, product.unit,
        newCategoryId: cat.id, newInventoryUnit: product.inventoryUnit);
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Изменено у ${selectedIds.length} товаров'),
    backgroundColor: const Color(0xFF2E3352),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
  setState(() {
    selectedIds.clear();
    onExitSelectMode();
  });
}

/// Массовая смена одного текстового поля (категория / ед. заявки / ед.
/// инвентаризации) у выбранных товаров.
Future<void> showBatchChangeProductsDialog({
  required BuildContext context,
  required SettingsRepository repo,
  required List<String> ids,
  required String title,
  required List<String> options,
  required void Function(SettingsRepository, String id, String newValue) onApply,
}) async {
  final result = await showProductOptionsDialog(context, title, options);
  if (result != null) {
    if (!context.mounted) return;
    for (final id in ids) {
      onApply(repo, id, result);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$title изменено у ${ids.length} товаров'),
      backgroundColor: const Color(0xFF2E3352),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

/// Диалог массового добавления товаров (по одному на строку).
void showBulkAddProductsDialog({
  required BuildContext context,
  required SettingsRepository repo,
  required List<DepartmentModel> depts,
  required List<CategoryModel> allCats,
  required AppLocalizations l,
  required bool isDark,
  required String? initialDepartmentId,
  required String? initialCategoryId,
}) {
  final ctrl = TextEditingController();
  // Если открыто из конкретной категории (Отдел → Категория → Товары) —
  // сразу предлагаем добавить товары именно в неё, а не в первую попавшуюся.
  String? selectedDeptId =
      initialDepartmentId ?? (depts.isNotEmpty ? depts.first.id : null);
  String? selectedCatId = initialCategoryId;
  String sUnit = 'шт';
  String sInvUnit = 'шт';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (_, set) {
        final filteredCats = selectedDeptId == null
            ? allCats
            : allCats.where((cat) => cat.departmentId == selectedDeptId).toList();
        if (selectedCatId == null && filteredCats.isNotEmpty) {
          selectedCatId = filteredCats.first.id;
        }
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.bulkAddProducts,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                  items: depts
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (v) => set(() {
                    selectedDeptId = v;
                    selectedCatId = null;
                  }),
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: filteredCats.any((c) => c.id == selectedCatId)
                      ? selectedCatId
                      : (filteredCats.isNotEmpty ? filteredCats.first.id : null),
                  dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                  items: filteredCats
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => set(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Товары, каждый с новой строки',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sUnit,
                  dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                  items: _kUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (заявка)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sInvUnit,
                  dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                  items: _kUnits
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sInvUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (инвент.)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              onPressed: () {
                final names = ctrl.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                if (names.isNotEmpty && selectedCatId != null) {
                  final duplicates = names
                      .where((n) => repo.isDuplicateProduct(n, selectedCatId!))
                      .toList();
                  if (duplicates.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Уже существуют: ${duplicates.join(', ')}'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                    return;
                  }
                  Navigator.pop(ctx);
                  repo.bulkAddProducts(names, sUnit, selectedCatId!,
                      defaultInventoryUnit: sInvUnit);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Добавлено ${names.length} товаров'),
                    backgroundColor: const Color(0xFF2E3352),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l.add),
            ),
          ],
        );
      },
    ),
  );
}
