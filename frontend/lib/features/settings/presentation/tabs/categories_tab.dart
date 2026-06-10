import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/widgets/animated_list_item.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(settingsRepositoryProvider).categories;
    final departments = ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, repo, departments, l10n),
        child: const Icon(Icons.add),
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade500),
                  const SizedBox(height: 16),
                  Text(l10n.noCategories, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final cat = categories[index];
                final dept = departments.firstWhere(
                  (d) => d.id == cat.departmentId,
                  orElse: () => DepartmentModel(id: '', name: 'Неизвестно', icon: Icons.help),
                );
                return AnimatedListItem(
                  child: Card(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    child: ListTile(
                      title: Text(cat.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      subtitle: Text('${l10n.department}: ${dept.name}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, repo, cat, l10n),
                      ),
                      onTap: () => _showEditDialog(context, repo, cat, departments, l10n),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo, CategoryModel cat, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirm),
        content: Text('${l.deleteConfirm} «${cat.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);               // сначала закрываем диалог
              repo.deleteCategory(cat.id);      // потом обновляем данные
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.successCategoryDeleted} «${cat.name}»')),
              );
            },
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    SettingsRepository repo,
    List<DepartmentModel> departments,
    AppLocalizations l,
  ) {
    final nameCtrl = TextEditingController();
    String? selectedDeptId = departments.isNotEmpty ? departments.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(l.addCategory),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (val) => setState(() => selectedDeptId = val),
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => navigator.pop(), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && selectedDeptId != null) {
                    navigator.pop();                             // сначала закрываем диалог
                    repo.addCategory(nameCtrl.text, selectedDeptId!);  // потом обновляем данные
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l.successCategoryAdded} «${nameCtrl.text}»')),
                    );
                  }
                },
                child: Text(l.add),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    SettingsRepository repo,
    CategoryModel cat,
    List<DepartmentModel> departments,
    AppLocalizations l,
  ) {
    final nameCtrl = TextEditingController(text: cat.name);
    String? selectedDeptId = cat.departmentId;

    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(l.editCategory),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (val) => setState(() => selectedDeptId = val),
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => navigator.pop(), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && selectedDeptId != null) {
                    navigator.pop();                             // сначала закрываем диалог
                    repo.updateCategory(cat.id, nameCtrl.text, newDepartmentId: selectedDeptId);  // потом обновляем данные
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l.successCategoryUpdated} «${nameCtrl.text}»')),
                    );
                  }
                },
                child: Text(l.save),
              ),
            ],
          ),
        );
      },
    );
  }
}