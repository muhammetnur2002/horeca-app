import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

/// Уровень 2 иерархии "Настройка товаров и отделов": категории конкретного
/// отдела (например, для "Бар" — Напитки, Кофе, Сиропы, Десерты...).
/// Нажатие на значок категории редактирует её название/флаг "десерты",
/// нажатие на строку — открывает товары этой категории.
class CatalogCategoriesScreen extends ConsumerWidget {
  final DepartmentModel department;
  const CatalogCategoriesScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final repo = ref.read(settingsRepositoryProvider.notifier);

    final categories = ref
        .watch(settingsRepositoryProvider)
        .categories
        .where((c) => c.departmentId == department.id)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(department.name,
            style: TextStyle(
                color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, repo, l10n, isDark),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
      body: Stack(children: [
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFF0F1629),
                                Color(0xFF1A1040),
                                Color(0xFF0D1F35)
                              ]
                            : const [
                                Color(0xFFEEF2FF),
                                Color(0xFFF5F7FF),
                                Color(0xFFEEF2FF)
                              ])))),
        SafeArea(
          child: categories.isEmpty
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: categories.length,
                  itemBuilder: (_, index) {
                    final cat = categories[index];
                    return _CatRow(
                      cat: cat,
                      isDark: isDark,
                      onEditIcon: () =>
                          _showEditDialog(context, repo, cat, l10n, isDark),
                      onOpen: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductsTab(
                                  initialDepartment: department,
                                  initialCategory: cat))),
                      onDelete: () =>
                          _confirmDelete(context, repo, cat, l10n, isDark),
                    );
                  },
                ),
        ),
      ]),
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
        content: Text('«${cat.name}» и все её товары будут удалены.',
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
                backgroundColor: const Color(0xFF2E3352),
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
      AppLocalizations l, bool isDark) {
    final nameCtrl = TextEditingController();
    bool isDessert = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                const SizedBox(height: 12),
                _DessertSwitch(
                  value: isDessert,
                  isDark: isDark,
                  onChanged: (v) => setState(() => isDessert = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    navigator.pop();
                    repo.addCategory(nameCtrl.text, department.id,
                        isDessertCategory: isDessert);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Категория «${nameCtrl.text}» добавлена'),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l.add),
              ),
            ],
          ),
        );
      },
    ).then((_) => nameCtrl.dispose());
  }

  void _showEditDialog(BuildContext context, SettingsRepository repo,
      CategoryModel cat, AppLocalizations l, bool isDark) {
    final nameCtrl = TextEditingController(text: cat.name);
    bool isDessert = cat.isDessertCategory;

    showDialog(
      context: context,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                const SizedBox(height: 12),
                _DessertSwitch(
                  value: isDessert,
                  isDark: isDark,
                  onChanged: (v) => setState(() => isDessert = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.pop(),
                child: Text(l.cancel, style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    navigator.pop();
                    repo.updateCategory(
                      cat.id,
                      nameCtrl.text,
                      isDessertCategory: isDessert,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Категория «${nameCtrl.text}» обновлена'),
                      backgroundColor: const Color(0xFF2E3352),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                    navigator.pop();
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

class _DessertSwitch extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _DessertSwitch(
      {required this.value, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.orange.withOpacity(value ? 0.1 : 0),
        border: Border.all(
            color: value
                ? AppColors.orange.withOpacity(0.3)
                : Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.icecream_outlined,
              size: 18, color: value ? AppColors.orange : AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Показывать в «Смена и списания»',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _CatRow extends StatelessWidget {
  final CategoryModel cat;
  final bool isDark;
  final VoidCallback onEditIcon;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _CatRow({
    required this.cat,
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
                      child: const Icon(Icons.folder_outlined,
                          color: AppColors.orange, size: 20),
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
                    child: Row(children: [
                      Flexible(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cat.isDessertCategory) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.icecream_outlined,
                            size: 14, color: AppColors.orange),
                      ],
                    ]),
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
