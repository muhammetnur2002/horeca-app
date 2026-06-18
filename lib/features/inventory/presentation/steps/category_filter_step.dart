import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class CategoryFilterStep extends ConsumerWidget {
  const CategoryFilterStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.departmentId == null) return const SizedBox.shrink();

    final allCategories = ref.watch(settingsRepositoryProvider).categories;
    final departmentCategories = state.departmentId == 'all'
        ? allCategories
        : allCategories
            .where((c) => c.departmentId == state.departmentId)
            .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
              : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Шаг 2',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Выберите категории',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: departmentCategories.length,
              itemBuilder: (_, index) {
                final cat = departmentCategories[index];
                final isSelected =
                    state.selectedCategoryIds.contains(cat.id);
                return GestureDetector(
                  onTap: () {
                    final updated =
                        List<String>.from(state.selectedCategoryIds);
                    if (isSelected) {
                      updated.remove(cat.id);
                    } else {
                      updated.add(cat.id);
                    }
                    ref
                        .read(inventoryStateProvider.notifier)
                        .setSelectedCategories(updated);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected
                              ? AppColors.orange.withOpacity(0.12)
                              : Colors.white
                                  .withOpacity(isDark ? 0.06 : 0.55),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.orange.withOpacity(0.4)
                                : Colors.white
                                    .withOpacity(isDark ? 0.1 : 0.8),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isSelected
                                    ? AppColors.orange
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.orange
                                      : AppColors.muted,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.orange
                                    : isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              onTap: () => ref
                  .read(inventoryStateProvider.notifier)
                  .confirmCategories(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.orange,
                    ),
                    child: const Text(
                      'Далее →',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
