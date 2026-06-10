import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/widgets/animated_list_item.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class ProductsTab extends ConsumerWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(settingsRepositoryProvider).products;
    final categories = ref.watch(settingsRepositoryProvider).categories;
    final departments = ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAdd(context, repo, departments, categories, l10n),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'bulk',
            onPressed: () => _showBulk(context, repo, departments, categories, l10n),
            child: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade500),
                  const SizedBox(height: 16),
                  Text(l10n.product, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (_, index) {
                final p = products[index];
                final cat = categories.firstWhere(
                  (c) => c.id == p.categoryId,
                  orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''),
                );
                final dept = departments.firstWhere(
                  (d) => d.id == cat.departmentId,
                  orElse: () => DepartmentModel(id: '', name: 'Неизвестно', icon: Icons.help),
                );
                return AnimatedListItem(
                  child: Card(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    child: ListTile(
                      title: Text(p.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      subtitle: Text('${p.unit} | ${dept.name} → ${cat.name}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, repo, p, l10n),
                      ),
                      onTap: () => _showEdit(context, repo, p, departments, categories, l10n),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo, ProductModel p, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirm),
        content: Text('${l.deleteConfirm} «${p.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);               // сначала закрываем диалог
              repo.deleteProduct(p.id);         // потом обновляем данные
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.successProductDeleted} «${p.name}»')),
              );
            },
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAdd(
    BuildContext c,
    SettingsRepository r,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
  ) {
    final ctrl = TextEditingController();
    String? selectedDeptId = depts.isNotEmpty ? depts.first.id : null;
    String? selectedCatId;
    String sUnit = 'кг';

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = _filteredCategories(selectedDeptId, allCats);
          if (selectedCatId != null && !filteredCats.any((cat) => cat.id == selectedCatId)) {
            selectedCatId = null;
          }
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }

          return AlertDialog(
            title: Text(l.addProduct),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: depts.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: filteredCats.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                  onChanged: (v) => set(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Название')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм.'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty && selectedCatId != null) {
                    Navigator.pop(ctx);                  // сначала закрываем диалог
                    r.addProduct(ctrl.text, sUnit, selectedCatId!);  // потом обновляем данные
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text('${l.successProductAdded} «${ctrl.text}»')),
                    );
                  }
                },
                child: Text(l.add),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulk(
    BuildContext c,
    SettingsRepository r,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
  ) {
    final ctrl = TextEditingController();
    String? selectedDeptId = depts.isNotEmpty ? depts.first.id : null;
    String? selectedCatId;
    String sUnit = 'шт';

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = _filteredCategories(selectedDeptId, allCats);
          if (selectedCatId != null && !filteredCats.any((cat) => cat.id == selectedCatId)) {
            selectedCatId = null;
          }
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }

          return AlertDialog(
            title: Text(l.bulkAddProducts),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: depts.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: filteredCats.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
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
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм.'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  final names = ctrl.text
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  if (names.isNotEmpty && selectedCatId != null) {
                    Navigator.pop(ctx);                  // сначала закрываем диалог
                    r.bulkAddProducts(names, sUnit, selectedCatId!);  // потом обновляем данные
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text('${l.successProductsBulkAdded} (${names.length})')),
                    );
                  }
                },
                child: Text(l.add),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEdit(
    BuildContext c,
    SettingsRepository r,
    ProductModel p,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
  ) {
    final ctrl = TextEditingController(text: p.name);
    final currentCat = allCats.firstWhere(
      (cat) => cat.id == p.categoryId,
      orElse: () => CategoryModel(id: '', name: '', departmentId: ''),
    );
    String? selectedDeptId = currentCat.departmentId.isNotEmpty ? currentCat.departmentId : (depts.isNotEmpty ? depts.first.id : null);
    String? selectedCatId = p.categoryId;
    String sUnit = p.unit;

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = _filteredCategories(selectedDeptId, allCats);
          if (selectedCatId != null && !filteredCats.any((cat) => cat.id == selectedCatId)) {
            selectedCatId = null;
          }
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }

          return AlertDialog(
            title: Text(l.editProduct),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: depts.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: filteredCats.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                  onChanged: (v) => set(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Название')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм.'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty && selectedCatId != null) {
                    Navigator.pop(ctx);                  // сначала закрываем диалог
                    r.updateProduct(p.id, ctrl.text, sUnit, newCategoryId: selectedCatId);  // потом обновляем данные
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text('${l.successProductUpdated} «${ctrl.text}»')),
                    );
                  }
                },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }

  List<CategoryModel> _filteredCategories(String? departmentId, List<CategoryModel> allCategories) {
    if (departmentId == null) return [];
    return allCategories.where((c) => c.departmentId == departmentId).toList();
  }
}