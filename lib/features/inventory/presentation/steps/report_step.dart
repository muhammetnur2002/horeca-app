import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/core/pdf_generator/pdf_generator.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class ReportStep extends ConsumerWidget {
  const ReportStep({super.key});

  String _getDeptName(String? departmentId, AppLocalizations l10n) {
    if (departmentId == 'all') return l10n.allDepartments;
    switch (departmentId) {
      case '1': return 'Кухня';
      case '2': return 'Бар';
      case '3': return 'Зал';
      case '4': return 'Склад';
      case '5': return 'Клининг';
      default: return departmentId ?? 'Неизвестный отдел';
    }
  }

  String _generateReport(
    InventoryState state,
    AppLocalizations l10n,
    String establishmentName,
    List<ProductModel> allProducts,
    List<CategoryModel> allCategories,
    List<DepartmentModel> allDepartments,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(l10n.reportTitle);
    buffer.writeln('${l10n.date}: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln('${l10n.establishment}: "$establishmentName"');
    buffer.writeln('${l10n.department}: ${_getDeptName(state.departmentId, l10n)}');
    buffer.writeln();

    final Map<String, List<InventoryItem>> grouped = {};
    final List<String> catOrder = [];

    for (final item in state.items) {
      final product = allProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductModel(id: '', name: item.productName, unit: '', inventoryUnit: '', categoryId: ''),
      );
      final category = allCategories.firstWhere(
        (c) => c.id == product.categoryId,
        orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''),
      );
      final catName = category.name.isNotEmpty ? category.name : 'Без категории';
      if (!grouped.containsKey(catName)) {
        grouped[catName] = [];
        catOrder.add(catName);
      }
      grouped[catName]!.add(item);
    }

    for (final catName in catOrder) {
      buffer.writeln('${l10n.category}: $catName');
      for (final item in grouped[catName]!) {
        buffer.writeln('- ${item.productName}: ${item.remaining} ${item.unit}');
      }
      buffer.writeln();
    }
    buffer.writeln('${l10n.responsible}: _______________');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(inventoryStateProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final establishmentName = settings.establishmentName;
    final allProducts = settings.products;
    final allCategories = settings.categories;
    final allDepartments = settings.departments;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deptName = _getDeptName(state.departmentId, l10n);
    final text = _generateReport(state, l10n, establishmentName,
        allProducts, allCategories, allDepartments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(historyRepositoryProvider);
      if (!repo.getAll().any(
          (e) => e.type == HistoryType.inventory && e.text == text)) {
        repo.add(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: HistoryType.inventory,
          title: '${l10n.inventory} $deptName',
          text: text,
          createdAt: DateTime.now(),
        ));
      }
    });

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Шаг 4',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  l10n.preview,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Текст отчёта
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: isDark
                              ? Colors.white.withOpacity(0.85)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.copy_rounded,
                    label: l10n.copy,
                    color: AppColors.muted,
                    isDark: isDark,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text)).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l10n.copySuccess),
                          backgroundColor: AppColors.darkCard,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.share_rounded,
                    label: l10n.share,
                    color: const Color(0xFF2AABEE),
                    isDark: isDark,
                    onTap: () => Share.share(text),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // PDF кнопка
            _ActionBtn(
              icon: Icons.picture_as_pdf_rounded,
              label: l10n.downloadPdf,
              color: AppColors.orange,
              isDark: isDark,
              fullWidth: true,
              onTap: () async {
                if (state.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.noData),
                    backgroundColor: AppColors.darkCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                  return;
                }
                try {
                  final pdfItems = state.items
                      .map((i) => {
                            'name': i.productName,
                            'remaining': i.remaining ==
                                    i.remaining.truncateToDouble()
                                ? i.remaining.toInt().toString()
                                : i.remaining.toString(),
                            'unit': i.unit.isNotEmpty ? i.unit : 'шт',
                          })
                      .toList();
                  final pdfBytes = await PdfGenerator.generateInventoryPdf(
                    establishmentName: establishmentName,
                    department: deptName,
                    items: pdfItems,
                    responsiblePerson: '_______________',
                  );
                  await PdfGenerator.downloadFile(pdfBytes,
                      'inventory_${DateTime.now().millisecondsSinceEpoch}.pdf');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Ошибка: $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
            ),

            const SizedBox(height: 10),

            // Редактировать и новая инвентаризация
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref
                        .read(inventoryStateProvider.notifier)
                        .backToInput(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white
                            .withOpacity(isDark ? 0.06 : 0.5),
                        border: Border.all(
                            color: Colors.white
                                .withOpacity(isDark ? 0.1 : 0.4)),
                      ),
                      child: Text(
                        l10n.edit,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(inventoryStateProvider.notifier)
                          .reset();
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.green.withOpacity(0.1),
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        l10n.newInventory,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.green),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool fullWidth;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
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
