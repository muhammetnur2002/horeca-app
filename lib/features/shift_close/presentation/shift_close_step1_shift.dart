/// Шаг 1 экрана "Закрытие смены" — кто работал и остатки/списания десертов.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_step1_dialogs.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_widgets.dart';

Widget buildShiftStep1({
  required BuildContext context,
  required WidgetRef ref,
  required StateSetter setState,
  required bool isDark,
  required int totalSteps,
  required Set<String> selectedStaff,
  required List<DessertItem> desserts,
  required bool dessertsLoaded,
  required List<ManualWriteOff> manualWriteOffs,
  required TextEditingController dessertSearchController,
  required String dessertSearch,
  required ValueChanged<String> onDessertSearchChanged,
  required void Function(List<DessertItem> desserts) onDessertsLoaded,
}) {
  final l10n = AppLocalizations.of(context);
  final staffList = ref.watch(settingsRepositoryProvider).staff;
  final filteredDesserts = dessertSearch.trim().isEmpty
      ? desserts
      : desserts.where((d) {
          final query = dessertSearch.toLowerCase().trim();
          final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
          final name = d.name.toLowerCase();
          return words.any((w) => name.contains(w));
        }).toList();
  final settings = ref.read(settingsRepositoryProvider);
  final showDesserts = settings.showShiftDesserts;
  if (showDesserts && !dessertsLoaded) {
    // Раньше категория для этого шага угадывалась по названию (искали
    // "десерт" в имени) — ломалось на любом другом написании. Теперь
    // это явный флаг isDessertCategory, который включается в
    // Настройки → Категории у нужной категории, независимо от названия.
    final catIds = settings.categories
        .where((c) => c.isDessertCategory)
        .map((c) => c.id)
        .toSet();
    final prods = settings.products
        .where((p) => catIds.contains(p.categoryId))
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onDessertsLoaded(prods.map((p) => DessertItem(name: p.name)).toList());
    });
  }

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    StepHeader(step: 1, total: totalSteps, title: 'Смена и списания'),
    const SizedBox(height: 16),

    GlassCard(
        isDark: isDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardLabel(text: 'Кто работал в смену'),
          const SizedBox(height: 10),
          staffList.isEmpty
              ? Text('Добавьте сотрудников в Настройки → Смена',
                  style: TextStyle(fontSize: 13, color: AppColors.muted))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: staffList.map((name) {
                    final sel = selectedStaff.contains(name);
                    return GestureDetector(
                        onTap: () => setState(() => sel
                            ? selectedStaff.remove(name)
                            : selectedStaff.add(name)),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: sel
                                    ? AppColors.orange.withOpacity(0.15)
                                    : Colors.white
                                        .withOpacity(isDark ? 0.06 : 0.5),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.orange.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.15))),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (sel)
                                    const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(Icons.check_rounded,
                                            size: 14,
                                            color: AppColors.orange)),
                                  Text(name,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: sel
                                              ? AppColors.orange
                                              : AppColors.muted)),
                                ])));
                  }).toList()),
        ])),

    if (showDesserts) ...[
      const SizedBox(height: 10),

      // Поиск десертов
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border:
                Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
        child: TextField(
          controller: dessertSearchController,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          decoration: InputDecoration(
              hintText: 'Поиск десерта...',
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.muted, size: 20),
              suffixIcon: dessertSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.muted, size: 18),
                      onPressed: () => setState(() {
                            dessertSearchController.clear();
                            onDessertSearchChanged('');
                          }))
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          onChanged: (v) => setState(() => onDessertSearchChanged(v)),
        ),
      ),
      const SizedBox(height: 10),

      GlassCard(
          isDark: isDark,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardLabel(text: 'Десерты — витрина'),
            const SizedBox(height: 10),
            filteredDesserts.isEmpty
                ? Text(
                    dessertSearch.isNotEmpty
                        ? 'Ничего не найдено'
                        : 'Добавьте товары в категорию "Десерты"',
                    style: TextStyle(fontSize: 13, color: AppColors.muted))
                : Column(
                    children: filteredDesserts
                        .map((d) => DessertRow(
                            name: d.name,
                            value: d.showcase,
                            onChanged: (v) => setState(() => d.showcase = v),
                            isDark: isDark))
                        .toList()),
          ])),

      const SizedBox(height: 10),

      GlassCard(
          isDark: isDark,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardLabel(text: 'Десерты — склад'),
            const SizedBox(height: 10),
            filteredDesserts.isEmpty
                ? Text(
                    dessertSearch.isNotEmpty
                        ? 'Ничего не найдено'
                        : 'Добавьте товары в категорию "Десерты"',
                    style: TextStyle(fontSize: 13, color: AppColors.muted))
                : Column(
                    children: filteredDesserts
                        .map((d) => DessertRow(
                            name: d.name,
                            value: d.stock,
                            onChanged: (v) => setState(() => d.stock = v),
                            isDark: isDark))
                        .toList()),
          ])),

      const SizedBox(height: 10),

      GlassCard(
          isDark: isDark,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardLabel(text: 'Списания — десерты'),
            const SizedBox(height: 10),
            filteredDesserts.isEmpty
                ? Text(
                    dessertSearch.isNotEmpty
                        ? 'Ничего не найдено'
                        : 'Добавьте товары в категорию "Десерты"',
                    style: TextStyle(fontSize: 13, color: AppColors.muted))
                : Column(
                    children: filteredDesserts
                        .map((d) => DessertRow(
                            name: d.name,
                            value: d.writeOff,
                            onChanged: (v) => setState(() => d.writeOff = v),
                            isDark: isDark,
                            isWriteOff: true))
                        .toList()),
          ])),
    ],

    const SizedBox(height: 10),

    GlassCard(
        isDark: isDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const CardLabel(text: 'Ручные списания'),
            GestureDetector(
                onTap: () => showAddManualWriteOffDialog(
                    context: context,
                    isDark: isDark,
                    setState: setState,
                    manualWriteOffs: manualWriteOffs),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.orange.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, size: 16, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(l10n.add,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600)),
                    ]))),
          ]),
          if (manualWriteOffs.isEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Нажмите + чтобы добавить списание вручную',
                    style: TextStyle(fontSize: 13, color: AppColors.muted))),
          ...manualWriteOffs.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.5))),
              child: Row(children: [
                Expanded(
                    child: Text(m.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E)))),
                QtyBtn(
                    icon: Icons.remove,
                    isDark: isDark,
                    onTap: () {
                      if (m.quantity > 1) setState(() => m.quantity--);
                    }),
                SizedBox(
                    width: 36,
                    child: Text('${m.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E)))),
                QtyBtn(
                    icon: Icons.add,
                    isDark: isDark,
                    onTap: () => setState(() => m.quantity++)),
                const SizedBox(width: 8),
                Text(m.unit,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 8),
                // 44×44 — тап-таргет, а не размер самой иконки (18px).
                GestureDetector(
                    onTap: () => setState(() => manualWriteOffs.removeAt(i)),
                    child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.close_rounded,
                            size: 18, color: Colors.redAccent))),
              ]),
            );
          }),
        ])),

    const SizedBox(height: 16),
  ]);
}
