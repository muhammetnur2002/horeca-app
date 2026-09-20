/// Мелкие виджеты экрана "Категории" (уровень 2 иерархии Отдел → Категория
/// → Товар). Вынесены из catalog_categories_screen.dart.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/shared/models/category_model.dart';

/// Переключатель "Показывать в «Смена и списания»" в диалогах добавления
/// и редактирования категории.
class DessertSwitch extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const DessertSwitch({
    super.key,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.orange.withOpacity(value ? 0.1 : 0),
        border: Border.all(
            color: value
                ? AppColors.orange.withOpacity(0.3)
                : Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.icecream_outlined,
              size: 18, color: value ? AppColors.orange : AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Показывать в «Смена и списания»',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.85)
                    : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

/// Строка одной категории в списке: значок (тап — редактировать),
/// название (тап — открыть товары категории), удаление.
class CatRow extends StatelessWidget {
  final CategoryModel cat;
  final bool isDark;
  final VoidCallback onEditIcon;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const CatRow({
    super.key,
    required this.cat,
    required this.isDark,
    required this.onEditIcon,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onEditIcon,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.folder_outlined,
                          color: AppColors.orange, size: 20),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              width: 1.5),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Flexible(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cat.isDessertCategory) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.icecream_outlined,
                            size: 14, color: AppColors.orange),
                      ],
                    ]),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
              GestureDetector(
                onTap: onOpen,
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
