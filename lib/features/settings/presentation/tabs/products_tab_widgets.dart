/// Мелкие виджеты экрана "Товары" (фильтр-чипы, карточка товара, панель
/// массового редактирования). Вынесены из products_tab.dart, чтобы основной
/// файл экрана было проще читать.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/shared/models/product_model.dart';

/// Чип-фильтр (используется и для отделов, и для категорий).
class ProductFilterChip extends StatelessWidget {
  final String? id;
  final String label;
  final bool isDark;
  final String? selectedId;
  final ValueChanged<String?> onTap;
  final Color color;

  const ProductFilterChip({
    super.key,
    required this.id,
    required this.label,
    required this.isDark,
    required this.selectedId,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedId == id;
    return GestureDetector(
      onTap: () => onTap(selected ? null : id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              selected ? color : Colors.white.withOpacity(isDark ? 0.06 : 0.5),
          border: Border.all(
            color:
                selected ? color : Colors.white.withOpacity(isDark ? 0.1 : 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}

/// Карточка товара в списке.
class ProductItemCard extends StatelessWidget {
  final ProductModel p;
  final String catName;
  final String deptName;
  final bool isDark;
  final bool isSelected;
  final bool selectMode;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onSetMinStock;

  const ProductItemCard({
    super.key,
    required this.p,
    required this.catName,
    required this.deptName,
    required this.isDark,
    required this.isSelected,
    required this.selectMode,
    required this.onSelect,
    required this.onSetMinStock,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected
                  ? AppColors.orange.withOpacity(0.12)
                  : Colors.white.withOpacity(isDark ? 0.06 : 0.55),
              border: Border.all(
                color: isSelected
                    ? AppColors.orange.withOpacity(0.4)
                    : Colors.white.withOpacity(isDark ? 0.1 : 0.8),
              ),
            ),
            child: Row(
              children: [
                if (selectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelect,
                    activeColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.orange, size: 18),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Заявка: ${p.unit} | Инвент: ${p.inventoryUnit} | $deptName → $catName',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!selectMode) ...[
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.orange, size: 20),
                    onPressed: onSetMinStock,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Маленькая кнопка в панели массового редактирования.
class BatchEditButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const BatchEditButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.orange.withOpacity(0.12),
          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Плавающая панель внизу списка, когда выбраны товары для массового
/// редактирования. Сама логика смены отдела/категории/единиц остаётся у
/// экрана — сюда передаются только готовые callback'и, чтобы не тащить
/// сюда список товаров и репозиторий.
class ProductBatchEditPanel extends StatelessWidget {
  final int selectedCount;
  final bool isDark;
  final VoidCallback onChangeDepartment;
  final VoidCallback onChangeCategory;
  final VoidCallback onChangeOrderUnit;
  final VoidCallback onChangeInventoryUnit;

  const ProductBatchEditPanel({
    super.key,
    required this.selectedCount,
    required this.isDark,
    required this.onChangeDepartment,
    required this.onChangeCategory,
    required this.onChangeOrderUnit,
    required this.onChangeInventoryUnit,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: isDark
              ? AppColors.darkSurface.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выбрано: $selectedCount',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      BatchEditButton(
                        icon: Icons.apartment_rounded,
                        label: 'Отдел',
                        onTap: onChangeDepartment,
                      ),
                      const SizedBox(width: 8),
                      BatchEditButton(
                        icon: Icons.folder_outlined,
                        label: 'Категорию',
                        onTap: onChangeCategory,
                      ),
                      const SizedBox(width: 8),
                      BatchEditButton(
                        icon: Icons.straighten_rounded,
                        label: 'Ед. заявки',
                        onTap: onChangeOrderUnit,
                      ),
                      const SizedBox(width: 8),
                      BatchEditButton(
                        icon: Icons.edit_rounded,
                        label: 'Ед. инвент.',
                        onTap: onChangeInventoryUnit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
