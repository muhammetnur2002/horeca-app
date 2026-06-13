import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class CategoryFilterStep extends ConsumerWidget {
  const CategoryFilterStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.departmentId == null) return const SizedBox.shrink();

    final allCategories = ref.watch(settingsRepositoryProvider).categories;

    // Если выбран "Все отделы", показываем ВСЕ категории,
    // иначе – только категории указанного отдела.
    final departmentCategories = state.departmentId == 'all'
        ? allCategories
        : allCategories.where((c) => c.departmentId == state.departmentId).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Выберите категории для инвентаризации',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: departmentCategories.length,
            itemBuilder: (_, index) {
              final cat = departmentCategories[index];
              final isSelected = state.selectedCategoryIds.contains(cat.id);
              return Card(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                child: CheckboxListTile(
                  title: Text(
                    cat.name,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  value: isSelected,
                  activeColor: Colors.orange,
                  checkColor: Colors.white,
                  onChanged: (bool? value) {
                    final updated = List<String>.from(state.selectedCategoryIds);
                    if (value == true) {
                      updated.add(cat.id);
                    } else {
                      updated.remove(cat.id);
                    }
                    ref.read(inventoryStateProvider.notifier).setSelectedCategories(updated);
                  },
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Переходим к вводу остатков
                ref.read(inventoryStateProvider.notifier).confirmCategories();
              },
              child: const Text('Далее'),
            ),
          ),
        ),
      ],
    );
  }
}