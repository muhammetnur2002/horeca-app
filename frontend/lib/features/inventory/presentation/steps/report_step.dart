import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final text = _generateReport(state, l10n, establishmentName, allProducts, allCategories, allDepartments);

    // ОТЛАДКА — убери после того как заработает
    debugPrint('=== ReportStep: items count = ${state.items.length}');
    for (final i in state.items) {
      debugPrint('  ${i.productName}: ${i.remaining} ${i.unit}');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(historyRepositoryProvider);
      if (!repo.getAll().any((e) => e.type == HistoryType.inventory && e.text == text)) {
        repo.add(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: HistoryType.inventory,
          title: '${l10n.inventory} $deptName',
          text: text,
          createdAt: DateTime.now(),
        ));
      }
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.preview, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text)).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.copySuccess)),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text(l10n.share),
                  onPressed: () => Share.share(text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(l10n.downloadPdf),
              onPressed: () async {
                // ОТЛАДКА
                debugPrint('=== PDF button pressed: items = ${state.items.length}');

                if (state.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noData)),
                  );
                  return;
                }
                try {
                  final pdfItems = state.items.map((i) => {
                    'name': i.productName,
                    'remaining': i.remaining == i.remaining.truncateToDouble()
                        ? i.remaining.toInt().toString()
                        : i.remaining.toString(),
                    'unit': i.unit.isNotEmpty ? i.unit : 'шт',
                  }).toList();

                  // ОТЛАДКА
                  debugPrint('=== pdfItems: $pdfItems');

                  final pdfBytes = await PdfGenerator.generateInventoryPdf(
                    establishmentName: establishmentName,
                    department: deptName,
                    items: pdfItems,
                    responsiblePerson: '_______________',
                  );
                  await PdfGenerator.downloadFile(
                    pdfBytes,
                    'inventory_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                } catch (e, stack) {
                  debugPrint('=== PDF error: $e\n$stack');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при создании PDF: $e')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(inventoryStateProvider.notifier).backToInput(),
            child: Text(l10n.edit),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(inventoryStateProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.newInventory),
          ),
        ],
      ),
    );
  }
}