/// Диалоги экрана "Товары" для одного товара: минимальный остаток, удаление,
/// добавление/редактирование. Массовые операции (выбор из списка, массовая
/// смена отдела/категории/полей, массовое добавление) — в
/// products_tab_batch_dialogs.dart.
/// Вынесены из products_tab.dart — там остаётся только сам список и фильтры.
library;

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

/// Диалог "Минимальный остаток" для одного товара.
void showMinStockDialog(
    BuildContext context, SettingsRepository repo, ProductModel p, bool isDark) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: p.minStock?.toString() ?? '');
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Минимальный остаток: ${p.name}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: 'Например: 5',
          suffixText: p.inventoryUnit,
          prefixIcon:
              const Icon(Icons.notifications_outlined, color: AppColors.orange),
        ),
      ),
      actions: [
        if (p.minStock != null)
          TextButton(
            onPressed: () {
              repo.setProductMinStock(p.id, null);
              Navigator.pop(ctx);
            },
            child:
                const Text('Убрать', style: TextStyle(color: Colors.redAccent)),
          ),
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted))),
        ElevatedButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text.replaceAll(',', '.'));
              repo.setProductMinStock(p.id, value);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(l10n.save)),
      ],
    ),
  );
}

/// Подтверждение удаления товара.
void confirmDeleteProduct(BuildContext context, SettingsRepository repo,
    ProductModel p, AppLocalizations l, bool isDark) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Удалить товар?',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: Text('«${p.name}» будет удалён.',
          style: TextStyle(color: AppColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            repo.deleteProduct(p.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('«${p.name}» удалён'),
              backgroundColor: const Color(0xFF2E3352),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l.delete),
        ),
      ],
    ),
  );
}

/// Общая форма диалога добавления/редактирования одного товара
/// (отдел, категория, название, ед. заявки, ед. инвентаризации).
AlertDialog buildProductEditDialog({
  required BuildContext ctx,
  required String title,
  required TextEditingController ctrl,
  required List<DepartmentModel> depts,
  required List<CategoryModel> allCats,
  required String? selectedDeptId,
  required String? selectedCatId,
  required String sUnit,
  required String sInvUnit,
  required bool isDark,
  required ValueChanged<String?> onDeptChanged,
  required ValueChanged<String?> onCatChanged,
  required ValueChanged<String> onUnitChanged,
  required ValueChanged<String> onInvUnitChanged,
  required VoidCallback onSave,
  required AppLocalizations l,
  required bool isEdit,
}) {
  final filteredCats = selectedDeptId == null
      ? allCats
      : allCats.where((cat) => cat.departmentId == selectedDeptId).toList();

  return AlertDialog(
    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedDeptId,
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            items: depts
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: onDeptChanged,
            decoration: const InputDecoration(labelText: 'Отдел'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: filteredCats.any((c) => c.id == selectedCatId)
                ? selectedCatId
                : (filteredCats.isNotEmpty ? filteredCats.first.id : null),
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            items: filteredCats
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: onCatChanged,
            decoration: const InputDecoration(labelText: 'Категория'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: !isEdit,
            decoration: InputDecoration(
              hintText: 'Название товара',
              prefixIcon:
                  const Icon(Icons.inventory_2_outlined, color: AppColors.orange),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: sUnit,
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            items: _kUnits
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (v) => onUnitChanged(v!),
            decoration: const InputDecoration(labelText: 'Ед. изм. (заявка)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: sInvUnit,
            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
            items: _kUnits
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (v) => onInvUnitChanged(v!),
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
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(isEdit ? l.save : l.add),
      ),
    ],
  );
}

/// Диалог редактирования существующего товара.
void showEditProductDialog({
  required BuildContext context,
  required SettingsRepository repo,
  required ProductModel p,
  required List<DepartmentModel> depts,
  required List<CategoryModel> allCats,
  required AppLocalizations l,
  required bool isDark,
}) {
  final ctrl = TextEditingController(text: p.name);
  final currentCat = allCats.firstWhere(
    (cat) => cat.id == p.categoryId,
    orElse: () => CategoryModel(id: '', name: '', departmentId: ''),
  );
  String? selectedDeptId = currentCat.departmentId.isNotEmpty
      ? currentCat.departmentId
      : (depts.isNotEmpty ? depts.first.id : null);
  String? selectedCatId = p.categoryId;
  String sUnit = p.unit;
  String sInvUnit = p.inventoryUnit;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (_, set) => buildProductEditDialog(
        ctx: ctx,
        title: l.editProduct,
        ctrl: ctrl,
        depts: depts,
        allCats: allCats,
        selectedDeptId: selectedDeptId,
        selectedCatId: selectedCatId,
        sUnit: sUnit,
        sInvUnit: sInvUnit,
        isDark: isDark,
        onDeptChanged: (v) => set(() {
          selectedDeptId = v;
          selectedCatId = null;
        }),
        onCatChanged: (v) => set(() => selectedCatId = v),
        onUnitChanged: (v) => set(() => sUnit = v),
        onInvUnitChanged: (v) => set(() => sInvUnit = v),
        onSave: () {
          if (ctrl.text.isNotEmpty && selectedCatId != null) {
            Navigator.pop(ctx);
            repo.updateProduct(p.id, ctrl.text, sUnit,
                newCategoryId: selectedCatId, newInventoryUnit: sInvUnit);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('«${ctrl.text}» обновлён'),
              backgroundColor: const Color(0xFF2E3352),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        l: l,
        isEdit: true,
      ),
    ),
  );
}
