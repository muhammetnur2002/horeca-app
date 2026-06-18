import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';

class InputRemainingStep extends ConsumerWidget {
  const InputRemainingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryStateProvider);
    if (state.departmentId == null) return const SizedBox.shrink();

    final allProducts = ref.watch(settingsRepositoryProvider).products;
    final allCategories = ref.watch(settingsRepositoryProvider).categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredProducts = allProducts.where((p) {
      final cat = allCategories.firstWhere(
        (c) => c.id == p.categoryId,
        orElse: () => CategoryModel(id: '', name: '', departmentId: ''),
      );
      if (!state.selectedCategoryIds.contains(cat.id)) return false;
      if (state.departmentId != 'all') {
        if (cat.departmentId.isNotEmpty &&
            cat.departmentId != state.departmentId) return false;
      }
      return true;
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryStateProvider.notifier).initItemsIfNeeded(
            filteredProducts
                .map((p) => InventoryItem(
                      productId: p.id,
                      productName: p.name,
                      remaining: 0,
                      unit: p.inventoryUnit.isNotEmpty
                          ? p.inventoryUnit
                          : p.unit,
                    ))
                .toList(),
          );
    });

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
                  'Шаг 3',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Введите остатки',
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
            child: state.items.isEmpty
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
                          child: Icon(Icons.inventory_2_outlined,
                              size: 36,
                              color: AppColors.muted.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text('Нет товаров',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.items.length,
                    itemBuilder: (_, index) {
                      final item = state.items[index];
                      final product = allProducts.firstWhere(
                        (p) => p.id == item.productId,
                        orElse: () => ProductModel(
                          id: '',
                          name: item.productName,
                          unit: item.unit,
                          inventoryUnit: item.unit,
                          categoryId: '',
                        ),
                      );
                      final category = allCategories.firstWhere(
                        (c) => c.id == product.categoryId,
                        orElse: () => CategoryModel(
                            id: '',
                            name: 'Без категории',
                            departmentId: ''),
                      );

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white
                                  .withOpacity(isDark ? 0.06 : 0.55),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                    isDark ? 0.1 : 0.8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
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
                                        category.name,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      width: 100,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        color: Colors.white.withOpacity(
                                            isDark ? 0.08 : 0.6),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                              isDark ? 0.15 : 0.5),
                                        ),
                                      ),
                                      child: TextField(
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal: true),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1A1A2E),
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          suffixText: item.unit,
                                          suffixStyle: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (val) {
                                          final parsed =
                                              double.tryParse(val) ?? 0;
                                          ref
                                              .read(inventoryStateProvider
                                                  .notifier)
                                              .updateRemaining(
                                                  item.productId, parsed);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: GestureDetector(
              onTap: () => ref
                  .read(inventoryStateProvider.notifier)
                  .generateReport(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.green,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Создать отчёт →',
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
