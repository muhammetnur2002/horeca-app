import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/core/pdf_generator/pdf_generator.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class GenerateStep extends ConsumerWidget {
  const GenerateStep({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Доброе утро!';
    if (hour >= 12 && hour < 18) return 'Добрый день!';
    return 'Добрый вечер!';
  }

  String _generateText(
    RequestState state,
    String establishmentName,
    List<ProductModel> allProducts,
    List<CategoryModel> allCategories,
    List<DepartmentModel> allDepartments,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(_getGreeting());
    buffer.writeln();
    buffer.writeln('Заявка для заведения “$establishmentName”.');
    buffer.writeln();

    // Сначала группируем по отделам, а внутри – по категориям
    final Map<String, Map<String, List<RequestItem>>> grouped = {};
    final List<String> departmentOrder = [];
    final Map<String, List<String>> categoryOrder = {};

    for (final item in state.items) {
      final product = allProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductModel(id: '', name: item.productName, unit: item.unit, categoryId: ''),
      );
      final category = allCategories.firstWhere(
        (c) => c.id == product.categoryId,
        orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''),
      );
      final department = allDepartments.firstWhere(
        (d) => d.id == category.departmentId,
        orElse: () => DepartmentModel(id: '', name: 'Неизвестный отдел', icon: Icons.help),
      );

      final deptName = department.name;
      final catName = category.name;

      if (!grouped.containsKey(deptName)) {
        grouped[deptName] = {};
        departmentOrder.add(deptName);
        categoryOrder[deptName] = [];
      }
      if (!grouped[deptName]!.containsKey(catName)) {
        grouped[deptName]![catName] = [];
        categoryOrder[deptName]!.add(catName);
      }
      grouped[deptName]![catName]!.add(item);
    }

    // Вывод по отделам и категориям
    for (final deptName in departmentOrder) {
      buffer.writeln('Отдел: $deptName');
      final cats = categoryOrder[deptName]!;
      for (final catName in cats) {
        buffer.writeln('Категория: $catName');
        for (final item in grouped[deptName]![catName]!) {
          buffer.writeln('- ${item.productName} — ${item.quantity} ${item.unit}');
        }
        buffer.writeln(); // пустая строка между категориями
      }
    }

    buffer.writeln('Спасибо!');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(requestStateProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final establishmentName = settings.establishmentName;
    final allProducts = settings.products;
    final allCategories = settings.categories;
    final allDepartments = settings.departments;

    final text = _generateText(state, establishmentName, allProducts, allCategories, allDepartments);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(historyRepositoryProvider);
      if (!repo.getAll().any((e) => e.type == HistoryType.request && e.text == text)) {
        repo.add(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: HistoryType.request,
          title: '${l10n.requestTitle} ${state.departmentId}',
          text: text,
          createdAt: DateTime.now(),
        ));
      }
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
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
          const SizedBox(height: 24),
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  onPressed: () => Share.share(text),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Telegram'),
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
                if (state.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.noData)),
                  );
                  return;
                }
                final pdfBytes = await PdfGenerator.generateRequestPdf(
                  title: l10n.requestTitle,
                  establishmentName: establishmentName,
                  department: state.departmentId ?? '',
                  items: state.items.map((i) => {
                    'name': i.productName,
                    'quantity': '${i.quantity}',
                    'unit': i.unit,
                  }).toList(),
                );
                PdfGenerator.downloadFile(pdfBytes, 'zayavka_${DateTime.now().millisecondsSinceEpoch}.pdf');
              },
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(requestStateProvider.notifier).goBack(),
            child: Text(l10n.edit),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(requestStateProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.newRequest),
          ),
        ],
      ),
    );
  }
}