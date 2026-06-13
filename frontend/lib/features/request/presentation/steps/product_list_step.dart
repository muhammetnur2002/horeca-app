import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/data/repositories/product_repository.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

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

  String _formatQuantity(double q) {
    return (q % 1 == 0) ? q.toInt().toString() : q.toStringAsFixed(1);
  }

  void _showQuantityDialog(BuildContext context, String productId, String productName, double currentQuantity, String unit, WidgetRef ref) {
    final controller = TextEditingController(text: currentQuantity.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.enterQuantity} ($productName)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          decoration: const InputDecoration(hintText: '0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              ref.read(requestStateProvider.notifier).updateItem(
                productId,
                val.toDouble(),
                productName: productName,
                unit: unit,
              );
              Navigator.pop(ctx);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestStateProvider);
    if (state.categoryId == null) {
      return Center(child: Text(AppLocalizations.of(context)!.selectCategory));
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
              hintText: AppLocalizations.of(context)!.searchProducts,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            onChanged: (value) => setState(() => _searchQuery = value),
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

              // Категория товара – возвращаем отображение!
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
                                style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                            Text(category.name,   // <-- категория снова здесь
                                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
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
                      GestureDetector(
                        onTap: () => _showQuantityDialog(
                          context,
                          product.id,
                          product.name,
                          currentItem.quantity,
                          product.unit,
                          ref,
                        ),
                        child: Text(
                          _formatQuantity(currentItem.quantity),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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
              onPressed: () => ref.read(requestStateProvider.notifier).goToGenerate(),
              child: Text(AppLocalizations.of(context)!.preview),
            ),
          ),
        ),
      ],
    );
  }
}