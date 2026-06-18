import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
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

  void _showQuantityDialog(BuildContext context, String productId,
      String productName, double currentQuantity, String unit, WidgetRef ref) {
    final controller =
        TextEditingController(text: currentQuantity.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${l10n.enterQuantity} ($productName)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: unit,
            prefixIcon: const Icon(Icons.inventory_2_outlined,
                color: AppColors.orange),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.muted)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.categoryId == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF)],
          ),
        ),
        child: Center(
          child: Text(l10n.selectCategory,
              style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    final products = ref.watch(productsProvider(state.categoryId!));
    final filtered = products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white
                        .withOpacity(isDark ? 0.06 : 0.55),
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(isDark ? 0.1 : 0.8),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchProducts,
                      hintStyle: TextStyle(color: AppColors.muted),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
            ),
          ),

          // Список товаров
          Expanded(
            child: filtered.isEmpty
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
                                color: AppColors.muted,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      final allCategories =
                          ref.read(settingsRepositoryProvider).categories;
                      final category = allCategories.firstWhere(
                        (c) => c.id == product.categoryId,
                        orElse: () => CategoryModel(
                            id: '',
                            name: 'Без категории',
                            departmentId: ''),
                      );
                      final hasQty = currentItem.quantity > 0;

                      return ClipRRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: hasQty
                                  ? AppColors.orange.withOpacity(0.08)
                                  : Colors.white.withOpacity(
                                      isDark ? 0.06 : 0.55),
                              border: Border.all(
                                color: hasQty
                                    ? AppColors.orange.withOpacity(0.3)
                                    : Colors.white.withOpacity(
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
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 15,
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
                                            fontSize: 12,
                                            color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                // Кнопка минус
                                GestureDetector(
                                  onTap: () {
                                    if (currentItem.quantity > 0) {
                                      ref
                                          .read(requestStateProvider
                                              .notifier)
                                          .updateItem(
                                            currentItem.productId,
                                            currentItem.quantity - 1,
                                            productName: product.name,
                                            unit: product.unit,
                                          );
                                    }
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                          isDark ? 0.08 : 0.6),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white
                                              .withOpacity(isDark
                                                  ? 0.1
                                                  : 0.3)),
                                    ),
                                    child: Icon(Icons.remove,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E)),
                                  ),
                                ),
                                // Количество
                                GestureDetector(
                                  onTap: () => _showQuantityDialog(
                                    context,
                                    product.id,
                                    product.name,
                                    currentItem.quantity,
                                    product.unit,
                                    ref,
                                  ),
                                  child: SizedBox(
                                    width: 40,
                                    child: Text(
                                      _formatQuantity(
                                          currentItem.quantity),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: hasQty
                                            ? AppColors.orange
                                            : isDark
                                                ? Colors.white
                                                : const Color(
                                                    0xFF1A1A2E),
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor: hasQty
                                            ? AppColors.orange
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                                // Кнопка плюс
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(
                                            requestStateProvider.notifier)
                                        .updateItem(
                                          currentItem.productId,
                                          currentItem.quantity + 1,
                                          productName: product.name,
                                          unit: product.unit,
                                        );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                          isDark ? 0.08 : 0.6),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white
                                              .withOpacity(isDark
                                                  ? 0.1
                                                  : 0.3)),
                                    ),
                                    child: Icon(Icons.add,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E)),
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

          // Кнопка предпросмотр
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: GestureDetector(
              onTap: () => ref
                  .read(requestStateProvider.notifier)
                  .goToGenerate(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.preview,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
