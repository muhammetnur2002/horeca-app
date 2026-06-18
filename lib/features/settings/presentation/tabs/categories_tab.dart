import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
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
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, repo, departments, l10n, isDark),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      body: categories.isEmpty
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
                    child: Icon(Icons.folder_open_outlined,
                        size: 36, color: AppColors.muted.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noCategories,
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 100),
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final cat = categories[index];
                final dept = departments.firstWhere(
                  (d) => d.id == cat.departmentId,
                  orElse: () => DepartmentModel(
                      id: '', name: 'Неизвестно', icon: Icons.help),
                );
                return _CatItem(
                  cat: cat,
                  deptName: dept.name,
                  isDark: isDark,
                  onDelete: () => _confirmDelete(context, repo, cat, l10n, isDark),
                  onEdit: () => _showEditDialog(context, repo, cat, departments, l10n, isDark),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo,
      CategoryModel cat, AppLocalizations l, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить категорию?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('«${cat.name}» будет удалена.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              repo.deleteCategory(cat.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Категория «${cat.name}» удалена'),
                backgroundColor: AppColors.darkCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, SettingsRepository repo,
      List<DepartmentModel> departments, AppLocalizations l, bool isDark) {
    final nameCtrl = TextEditingController();
    String? selectedDeptId =
        departments.isNotEmpty ? departments.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(l.addCategory,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Название категории',
                    prefixIcon: const Icon(Icons.folder_outlined,
                        color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  dropdownColor:
                      isDark ? AppColors.darkCard : Colors.white,
                  items: departments
                      .map((d) => DropdownMenuItem(
                          value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedDeptId = val),
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text(l.cancel,
                    style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && selectedDeptId != null) {
                    navigator.pop();
                    repo.addCategory(nameCtrl.text, selectedDeptId!);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Категория «${nameCtrl.text}» добавлена'),
                      backgroundColor: AppColors.darkCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
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
      bool isDark) {
    final nameCtrl = TextEditingController(text: cat.name);
    String? selectedDeptId = cat.departmentId;

    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(l.editCategory,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Название категории',
                    prefixIcon: const Icon(Icons.folder_outlined,
                        color: AppColors.orange),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  dropdownColor:
                      isDark ? AppColors.darkCard : Colors.white,
                  items: departments
                      .map((d) => DropdownMenuItem(
                          value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedDeptId = val),
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text(l.cancel,
                    style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && selectedDeptId != null) {
                    navigator.pop();
                    repo.updateCategory(cat.id, nameCtrl.text,
                        newDepartmentId: selectedDeptId);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Категория «${nameCtrl.text}» обновлена'),
                      backgroundColor: AppColors.darkCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l.save),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatItem extends StatelessWidget {
  final CategoryModel cat;
  final String deptName;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _CatItem({
    required this.cat,
    required this.deptName,
    required this.isDark,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color:
                  Colors.white.withOpacity(isDark ? 0.06 : 0.55),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_outlined,
                      color: AppColors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Отдел: $deptName',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}