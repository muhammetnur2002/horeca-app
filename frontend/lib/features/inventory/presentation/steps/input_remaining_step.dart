import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/inventory/data/repositories/inventory_product_repository.dart';
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
      final cat = allCategories.firstWhere((c) => c.id == p.categoryId, orElse: () => CategoryModel(id: '', name: '', departmentId: ''));
      if (state.departmentId == 'all') {
        return state.selectedCategoryIds.contains(cat.id);
      } else {
        return cat.departmentId == state.departmentId && state.selectedCategoryIds.contains(cat.id);
      }
    }).toList();

    if (state.items.isEmpty || !_listsEqual(state.items, filteredProducts)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(inventoryStateProvider.notifier).initItems(
          filteredProducts.map((p) => InventoryItem(
            productId: p.id,
            productName: p.name,
            remaining: 0,
            unit: p.inventoryUnit,   // <-- используем единицу для инвентаризации
          )).toList(),
        );
      });
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (_, index) {
              final item = state.items[index];
              final product = allProducts.firstWhere((p) => p.id == item.productId, orElse: () => ProductModel(id: '', name: item.productName, unit: item.unit, inventoryUnit: item.unit, categoryId: ''));
              final category = allCategories.firstWhere((c) => c.id == product.categoryId, orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''));

              return Card(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                            Text(category.name, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            isDense: true,
                            suffixText: item.unit,  // <-- отображаем inventoryUnit
                            border: const OutlineInputBorder(),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0;
                            ref.read(inventoryStateProvider.notifier).updateRemaining(item.productId, parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => ref.read(inventoryStateProvider.notifier).generateReport(),
              child: const Text('Создать отчёт'),
            ),
          ),
        ),
      ],
    );
  }

  bool _listsEqual(List<InventoryItem> items, List<ProductModel> products) {
    if (items.length != products.length) return false;
    for (int i = 0; i < items.length; i++) {
      if (items[i].productId != products[i].id) return false;
    }
    return true;
  }
}