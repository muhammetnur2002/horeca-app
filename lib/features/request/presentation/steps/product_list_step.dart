import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/request/data/repositories/product_repository.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/shared/widgets/quantity_stepper.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestStateProvider);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.categoryId == null) {
      return Container(
        decoration: BoxDecoration(
        ),
        child: Center(
          child: Text(l10n.selectCategory,
              style: TextStyle(color: AppColors.muted)),
        ),
      );
    }

    final products = ref.watch(productsProvider(state.categoryId!));
    final levels = ref.watch(stockLevelsRepositoryProvider);
    final selectedCount = state.items.where((i) => i.quantity > 0).length;
    final filtered = products
        .where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
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
                      color: isDark ? Colors.white : AppColors.ink,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchProducts,
                      hintStyle: TextStyle(color: AppColors.muted),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: AppColors.muted, size: 18),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              }))
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      final hasQty = currentItem.quantity > 0;
                      // Под названием — единица и последний остаток; если
                      // товар ниже минимума, подпись подсвечивается.
                      final level = levels[product.id];
                      final low = level != null &&
                          product.minStock != null &&
                          level < product.minStock!;
                      final levelText = level == null
                          ? product.unit
                          : '${product.unit} · остаток ${level == level.roundToDouble() ? level.toInt() : level.toStringAsFixed(1).replaceAll('.', ',')}'
                              '${product.inventoryUnit != null && product.inventoryUnit != product.unit ? ' ${product.inventoryUnit}' : ''}';

                      return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: hasQty
                                  ? AppColors.green.withOpacity(0.07)
                                  : Colors.white.withOpacity(
                                      isDark ? 0.06 : 0.6),
                              border: Border.all(
                                width: hasQty ? 1.4 : 1,
                                color: hasQty
                                    ? AppColors.green.withOpacity(0.7)
                                    : Colors.white.withOpacity(
                                        isDark ? 0.1 : 0.85),
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
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        levelText,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: low
                                                ? AppColors.accent3
                                                : AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                QuantityStepper(
                                  value: currentItem.quantity,
                                  unit: product.unit,
                                  isDark: isDark,
                                  productName: product.name,
                                  allowDecimal: false,
                                  onChanged: (v) => ref
                                      .read(requestStateProvider.notifier)
                                      .updateItem(
                                        currentItem.productId,
                                        v,
                                        productName: product.name,
                                        unit: product.unit,
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

          // Нижняя панель: сколько позиций в заявке и предпросмотр.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.7),
                    border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.12 : 0.9)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('В заявке',
                              style: TextStyle(
                                  fontSize: 11.5, color: AppColors.muted)),
                          Text(
                            '$selectedCount ${_positions(selectedCount)}',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(requestStateProvider.notifier)
                          .goToGenerate(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [AppColors.orange, AppColors.green],
                          ),
                        ),
                        child: Text(
                          l10n.preview,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _positions(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return 'позиция';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'позиции';
  return 'позиций';
}
