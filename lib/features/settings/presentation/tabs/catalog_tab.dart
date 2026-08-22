import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:horeca_app/features/settings/presentation/tabs/catalog_categories_screen.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

/// Уровень 1 иерархии "Настройка товаров и отделов": список отделов.
/// Раньше "Отделы", "Категории" и "Товары" были тремя разными вкладками —
/// теперь это один экран с проваливанием вглубь: отдел → категории этого
/// отдела → товары этой категории. Нажатие на значок отдела редактирует
/// его название, нажатие на саму строку — открывает его категории.
class CatalogTab extends ConsumerWidget {
  const CatalogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                        size: 36, color: AppColors.muted.withOpacity(0.5)),
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
              padding: const EdgeInsets.fromLTRB(16, 130, 16, 100),
              itemCount: departments.length,
              itemBuilder: (_, index) {
                final dept = departments[index];
                return _DeptRow(
                  dept: dept,
                  isDark: isDark,
                  onEditIcon: () =>
                      _showEditDialog(context, repo, dept, l10n, isDark),
                  onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CatalogCategoriesScreen(department: dept))),
                  onDelete: () =>
                      _confirmDelete(context, repo, dept, l10n, isDark),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить отдел?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text(
            '«${dept.name}» и все его категории с товарами будут удалены.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              repo.deleteDepartment(dept.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Отдел «${dept.name}» удалён'),
                  backgroundColor: const Color(0xFF2E3352),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                repo.addDepartment(nameCtrl.text, Icons.category);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Отдел «${nameCtrl.text}» добавлен'),
                    backgroundColor: const Color(0xFF2E3352),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                repo.updateDepartment(dept.id, nameCtrl.text, null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Отдел «${nameCtrl.text}» обновлён'),
                    backgroundColor: const Color(0xFF2E3352),
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

class _DeptRow extends StatelessWidget {
  final DepartmentModel dept;
  final bool isDark;
  final VoidCallback onEditIcon;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _DeptRow({
    required this.dept,
    required this.isDark,
    required this.onEditIcon,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
            ),
          ),
          child: Row(
            children: [
              // Значок отдела — отдельная зона нажатия для редактирования
              // названия, чтобы не путать с переходом в категории.
              GestureDetector(
                onTap: onEditIcon,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(dept.icon, color: AppColors.orange, size: 20),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              width: 1.5),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      dept.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
              GestureDetector(
                onTap: onOpen,
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
