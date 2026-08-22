/// Диалоги экрана "Категории": удаление, добавление, редактирование.
/// Вынесены из catalog_categories_screen.dart.
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:horeca_app/features/settings/presentation/tabs/catalog_categories_widgets.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';

void confirmDeleteCategory(BuildContext context, SettingsRepository repo,
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
            if (!context.mounted) return;
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l.delete),
        ),
      ],
    ),
  );
}

void showAddCategoryDialog({
  required BuildContext context,
  required SettingsRepository repo,
  required DepartmentModel department,
  required AppLocalizations l,
  required bool isDark,
}) {
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
              DessertSwitch(
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
                  if (!context.mounted) return;
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

void showEditCategoryDialog({
  required BuildContext context,
  required SettingsRepository repo,
  required CategoryModel cat,
  required AppLocalizations l,
  required bool isDark,
}) {
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
              DessertSwitch(
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
                  repo.updateCategory(cat.id, nameCtrl.text,
                      isDessertCategory: isDessert);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Категория «${nameCtrl.text}» обновлена'),
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
              child: Text(l.save),
            ),
          ],
        ),
      );
    },
  );
}
