import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/data/repositories/department_repository.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class SelectDepartmentStep extends ConsumerWidget {
  const SelectDepartmentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = ref.watch(settingsRepositoryProvider).categories;

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: departments.length + 1, // +1 для "Все отделы"
      itemBuilder: (_, index) {
        if (index == 0) {
          return Card(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            child: InkWell(
              onTap: () {
                final allCategoryIds = allCategories.map((c) => c.id).toList();
                ref.read(inventoryStateProvider.notifier).selectDepartment('all', allCategoryIds);
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.all_inclusive, size: 48, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    l10n.allDepartments,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                ],
              ),
            ),
          );
        }
        final d = departments[index - 1];
        return Card(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          child: InkWell(
            onTap: () {
              final categoryIds = allCategories
                  .where((c) => c.departmentId == d.id)
                  .map((c) => c.id)
                  .toList();
              ref.read(inventoryStateProvider.notifier).selectDepartment(d.id, categoryIds);
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(d.icon, size: 48, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  d.name, // <-- реальное имя
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}