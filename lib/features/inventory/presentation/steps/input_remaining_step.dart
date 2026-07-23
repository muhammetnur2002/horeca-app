import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';

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
            cat.departmentId != state.departmentId) return false;
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
        orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''),
      );
      grouped.putIfAbsent(cat.name, () => []).add(p);
    }

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'Поиск товара...',
                    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.muted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
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
                      style: const TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                  letterSpacing: 0.6),
                            ),
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
                                    .updateItem(p.id, p.name,
                                        p.inventoryUnit, value);
                              },
                            );
                          }),
                        ],
                      );
                    }).toList(),
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

  void _showManualInput(BuildContext context) {
    final ctrl = TextEditingController(
        text: item.remaining == 0 ? '' : '${item.remaining}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
              hintText: '0', suffixText: product.inventoryUnit),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(
                      ctrl.text.replaceAll(',', '.')) ??
                  item.remaining;
              onChanged(v < 0 ? 0 : v);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(product.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E))),
                Text(product.inventoryUnit,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
              ]),
            ),
            _QtyBtn(
                icon: Icons.remove,
                isDark: isDark,
                onTap: () {
                  if (item.remaining > 0)
                    onChanged(item.remaining - 1);
                }),
            GestureDetector(
              onTap: () => _showManualInput(context),
              child: SizedBox(
                width: 40,
                child: Text(
                  item.remaining == item.remaining.truncateToDouble()
                      ? item.remaining.toInt().toString()
                      : item.remaining.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A2E)),
                ),
              ),
            ),
            _QtyBtn(
                icon: Icons.add,
                isDark: isDark,
                onTap: () => onChanged(item.remaining + 1)),
          ]),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _QtyBtn(
      {required this.icon, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(isDark ? 0.08 : 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.white
                      .withOpacity(isDark ? 0.1 : 0.3))),
          child: Icon(icon,
              size: 16,
              color: isDark
                  ? Colors.white
                  : const Color(0xFF1A1A2E)),
        ),
      );
}