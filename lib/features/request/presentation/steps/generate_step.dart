import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
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

  String _formatDouble(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
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
    buffer.writeln('Заявка для заведения "$establishmentName".');
    buffer.writeln();

    final Map<String, Map<String, List<RequestItem>>> grouped = {};
    final List<String> departmentOrder = [];
    final Map<String, List<String>> categoryOrder = {};

    for (final item in state.items) {
      final product = allProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductModel(
            id: '', name: item.productName, unit: item.unit, categoryId: ''),
      );
      final category = allCategories.firstWhere(
        (c) => c.id == product.categoryId,
        orElse: () =>
            CategoryModel(id: '', name: 'Без категории', departmentId: ''),
      );
      final department = allDepartments.firstWhere(
        (d) => d.id == category.departmentId,
        orElse: () => DepartmentModel(
            id: '', name: 'Неизвестный отдел', icon: Icons.help),
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

    for (final deptName in departmentOrder) {
      buffer.writeln('Отдел: $deptName');
      for (final catName in categoryOrder[deptName]!) {
        buffer.writeln('Категория: $catName');
        for (final item in grouped[deptName]![catName]!) {
          buffer.writeln(
              '- ${item.productName} — ${_formatDouble(item.quantity)} ${item.unit}');
        }
        buffer.writeln();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = _generateText(
        state, establishmentName, allProducts, allCategories, allDepartments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(historyRepositoryProvider);
      if (!repo
          .getAll()
          .any((e) => e.type == HistoryType.request && e.text == text)) {
        repo.add(HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: HistoryType.request,
          title: '${l10n.requestTitle} ${state.departmentId}',
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
                const Text('Предпросмотр',
                    style: TextStyle(
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

            // Текст заявки
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color:
                          Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                      border: Border.all(
                        color: Colors.white
                            .withOpacity(isDark ? 0.1 : 0.8),
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

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.copy_rounded,
                    label: l10n.copy,
                    color: AppColors.muted,
                    isDark: isDark,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text))
                          .then((_) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
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

            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    isDark: isDark,
                    onTap: () => Share.share(text),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.send_rounded,
                    label: 'Telegram',
                    color: const Color(0xFF2AABEE),
                    isDark: isDark,
                    onTap: () => Share.share(text),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

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
                final pdfBytes = await PdfGenerator.generateRequestPdf(
                  title: l10n.requestTitle,
                  establishmentName: establishmentName,
                  department: state.departmentId ?? '',
                  items: state.items
                      .map((i) => {
                            'name': i.productName,
                            'quantity': _formatDouble(i.quantity),
                            'unit': i.unit,
                          })
                      .toList(),
                );
                PdfGenerator.downloadFile(pdfBytes,
                    'zayavka_${DateTime.now().millisecondsSinceEpoch}.pdf');
              },
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(requestStateProvider.notifier).goBack(),
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
                        style:
                            TextStyle(fontSize: 14, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(requestStateProvider.notifier).reset();
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
                        l10n.newRequest,
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
                vertical: 13, horizontal: 16),
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