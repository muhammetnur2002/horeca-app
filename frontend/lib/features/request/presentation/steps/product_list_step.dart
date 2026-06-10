import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/data/repositories/product_repository.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';

class ProductListStep extends ConsumerStatefulWidget {
  const ProductListStep({super.key});

  @override
  ConsumerState<ProductListStep> createState() => _ProductListStepState();
}

class _ProductListStepState extends ConsumerState<ProductListStep> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestStateProvider);
    if (state.categoryId == null) {
      return const Center(child: Text('Сначала выберите категорию'));
    }
    final products = ref.watch(productsProvider(state.categoryId!));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск товаров...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (_, index) {
              final product = filtered[index];
              final currentItem = state.items.firstWhere(
                (i) => i.productId == product.id,
                orElse: () => RequestItem(
                  productId: product.id,
                  productName: product.name,
                  quantity: 0,
                  unit: product.unit,
                ),
              );

              // Определяем категорию товара
              final allCategories = ref.read(settingsRepositoryProvider).categories;
              final category = allCategories.firstWhere(
                (c) => c.id == product.categoryId,
                orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''),
              );

              return Card(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: TextStyle(
                                    fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                            Text(category.name,
                                style: TextStyle(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        onPressed: () {
                          if (currentItem.quantity > 0) {
                            ref.read(requestStateProvider.notifier).updateItem(
                                  currentItem.productId,
                                  currentItem.quantity - 1,
                                  productName: product.name,
                                  unit: product.unit,
                                );
                          }
                        },
                      ),
                      Text(
                        '${currentItem.quantity}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        onPressed: () {
                          ref.read(requestStateProvider.notifier).updateItem(
                                currentItem.productId,
                                currentItem.quantity + 1,
                                productName: product.name,
                                unit: product.unit,
                              );
                        },
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
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                ref.read(requestStateProvider.notifier).goToGenerate();
              },
              child: const Text('Далее'),
            ),
          ),
        ),
      ],
    );
  }
}