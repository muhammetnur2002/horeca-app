/// Поиск и фильтры экрана "Товары": строка поиска и два ряда чипов
/// (отдел / категория). Вынесены из products_tab.dart, чтобы не раздувать
/// его build().
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_widgets.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';

/// Поле поиска по названию товара.
Widget buildProductsSearchField({
  required TextEditingController controller,
  required String searchQuery,
  required bool isDark,
  required AppLocalizations l10n,
  required ValueChanged<String> onChanged,
  required VoidCallback onClear,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
            ),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              hintStyle: TextStyle(color: AppColors.muted),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.muted, size: 18),
                      onPressed: onClear)
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}

/// Ряд чипов фильтра по отделу.
Widget buildDepartmentFilterRow({
  required List<DepartmentModel> departments,
  required String? selectedDeptId,
  required bool isDark,
  required ValueChanged<String?> onSelect,
}) {
  return SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        ProductFilterChip(
            id: null,
            label: 'Все отделы',
            isDark: isDark,
            selectedId: selectedDeptId,
            onTap: onSelect,
            color: AppColors.orange),
        ...departments.map((d) => ProductFilterChip(
            id: d.id,
            label: d.name,
            isDark: isDark,
            selectedId: selectedDeptId,
            onTap: onSelect,
            color: AppColors.orange)),
      ],
    ),
  );
}

/// Ряд чипов фильтра по категории.
Widget buildCategoryFilterRow({
  required List<CategoryModel> availableCategories,
  required String? selectedCatId,
  required bool isDark,
  required ValueChanged<String?> onSelect,
}) {
  return SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        ProductFilterChip(
            id: null,
            label: 'Все категории',
            isDark: isDark,
            selectedId: selectedCatId,
            onTap: onSelect,
            color: AppColors.green),
        ...availableCategories.map((c) => ProductFilterChip(
            id: c.id,
            label: c.name,
            isDark: isDark,
            selectedId: selectedCatId,
            onTap: onSelect,
            color: AppColors.green)),
      ],
    ),
  );
}
