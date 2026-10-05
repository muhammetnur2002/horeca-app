import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/shared/widgets/orbit_kit.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/widgets/quantity_stepper.dart';

class InputRemainingStep extends ConsumerStatefulWidget {
  const InputRemainingStep({super.key});
  @override
  ConsumerState<InputRemainingStep> createState() => _InputRemainingStepState();
}

class _InputRemainingStepState extends ConsumerState<InputRemainingStep> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            cat.departmentId != state.departmentId) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    final Map<String, List<ProductModel>> grouped = {};
    for (final p in filteredProducts) {
      final cat = allCategories.firstWhere(
        (c) => c.id == p.categoryId,
        orElse: () =>
            CategoryModel(id: '', name: 'Без категории', departmentId: ''),
      );
      grouped.putIfAbsent(cat.name, () => []).add(p);
    }

    return Container(
      decoration: BoxDecoration(
      ),
      child: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Поиск товара...',
                    hintStyle:
                        TextStyle(color: AppColors.muted, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.muted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: AppColors.muted, size: 18),
                            onPressed: () => setState(() {
                                  _searchCtrl.clear();
                                  _searchQuery = '';
                                }))
                        : null,
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

          // Список товаров
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Ничего не найдено'
                          : 'Нет товаров',
                      style:
                          TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OrbitSectionLabel(
                            '${entry.key} · введите факт',
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                          ),
                          ...entry.value.map((p) {
                            final item = state.items.firstWhere(
                              (i) => i.productId == p.id,
                              orElse: () => InventoryItem(
                                  productId: p.id,
                                  productName: p.name,
                                  remaining: 0,
                                  unit: p.inventoryUnit),
                            );
                            return _ProductRow(
                              product: p,
                              item: item,
                              isDark: isDark,
                              onChanged: (value) {
                                ref
                                    .read(inventoryStateProvider.notifier)
                                    .updateItem(
                                        p.id, p.name, p.inventoryUnit, value);
                              },
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          // Главное действие — градиент темы.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: OrbitPrimaryButton(
              label: 'Предпросмотр',
              icon: Icons.visibility_outlined,
              onTap: () =>
                  ref.read(inventoryStateProvider.notifier).generateReport(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final InventoryItem item;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _ProductRow({
    required this.product,
    required this.item,
    required this.isDark,
    required this.onChanged,
  });

  /// Весовые и объёмные товары считают с шагом 0,5, штучные — по одному.
  static double _stepFor(String unit) {
    final u = unit.toLowerCase();
    return (u == 'кг' || u == 'л') ? 0.5 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final hasQty = item.remaining > 0;
    final min = product.minStock;
    final low = hasQty && min != null && item.remaining < min;
    String q(double v) => v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString().replaceAll('.', ',');
    final sub = min == null
        ? product.inventoryUnit
        : '${product.inventoryUnit} · ${low ? 'ниже минимума' : 'минимум'} ${q(min)}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: hasQty
                ? AppColors.green.withOpacity(0.07)
                : Colors.white.withOpacity(isDark ? 0.06 : 0.6),
            border: Border.all(
              width: hasQty ? 1.4 : 1,
              color: low
                  ? AppColors.accent3.withOpacity(0.7)
                  : hasQty
                      ? AppColors.green.withOpacity(0.7)
                      : Colors.white.withOpacity(isDark ? 0.1 : 0.85),
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.ink)),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 12,
                            color: low ? AppColors.accent3 : AppColors.muted)),
                  ]),
            ),
            QuantityStepper(
              value: item.remaining,
              unit: product.inventoryUnit,
              isDark: isDark,
              productName: product.name,
              allowDecimal: true,
              step: _stepFor(product.inventoryUnit),
              onChanged: onChanged,
            ),
          ]),
        ),
      ),
    );
  }
}
