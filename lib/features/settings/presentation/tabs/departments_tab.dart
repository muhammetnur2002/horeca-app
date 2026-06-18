import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class DepartmentsTab extends ConsumerWidget {
  const DepartmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final departments = ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, repo, l10n, isDark),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      body: departments.isEmpty
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
                    child: Icon(Icons.store_outlined,
                        size: 36,
                        color: AppColors.muted.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noDepartments,
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 100),
              itemCount: departments.length,
              itemBuilder: (_, index) {
                final dept = departments[index];
                return _DeptItem(
                  dept: dept,
                  isDark: isDark,
                  onDelete: () =>
                      _confirmDelete(context, repo, dept, l10n, isDark),
                  onEdit: () =>
                      _showEditDialog(context, repo, dept, l10n, isDark),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo,
      DepartmentModel dept, AppLocalizations l, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить отдел?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('«${dept.name}» будет удалён.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              repo.deleteDepartment(dept.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Отдел «${dept.name}» удалён'),
                  backgroundColor: AppColors.darkCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
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
      AppLocalizations l, bool isDark) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.addDepartment,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Название отдела',
            prefixIcon:
                const Icon(Icons.store_outlined, color: AppColors.orange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                repo.addDepartment(nameCtrl.text, Icons.category);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Отдел «${nameCtrl.text}» добавлен'),
                    backgroundColor: AppColors.darkCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
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
  }

  void _showEditDialog(BuildContext context, SettingsRepository repo,
      DepartmentModel dept, AppLocalizations l, bool isDark) {
    final nameCtrl = TextEditingController(text: dept.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.editDepartment,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Название отдела',
            prefixIcon:
                const Icon(Icons.store_outlined, color: AppColors.orange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                repo.updateDepartment(dept.id, nameCtrl.text, null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Отдел «${nameCtrl.text}» обновлён'),
                    backgroundColor: AppColors.darkCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
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
  }
}

class _DeptItem extends StatelessWidget {
  final DepartmentModel dept;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _DeptItem({
    required this.dept,
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
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
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
                  child: Icon(dept.icon,
                      color: AppColors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dept.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                    ),
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
