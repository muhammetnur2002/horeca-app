import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/shared/widgets/orbit_kit.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
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

  /// state.departmentId — это внутренний id (например "dept_17..."), а не
  /// человекочитаемое название, поэтому раньше оно печаталось в истории и в
  /// PDF как есть. Вдобавок автособранные заявки (из остатков iiko) вообще
  /// не привязаны к одному отделу — items могут быть из разных отделов сразу.
  /// Поэтому определяем название(я) отдела по самим товарам в заявке.
  String _resolveDepartmentLabel(
    RequestState state,
    List<ProductModel> allProducts,
    List<CategoryModel> allCategories,
    List<DepartmentModel> allDepartments,
  ) {
    final names = <String>{};
    for (final item in state.items) {
      final product = allProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductModel(
            id: '', name: item.productName, unit: item.unit, categoryId: ''),
      );
      final category = allCategories.firstWhere(
        (c) => c.id == product.categoryId,
        orElse: () =>
            CategoryModel(id: '', name: '', departmentId: ''),
      );
      final department = allDepartments.firstWhere(
        (d) => d.id == category.departmentId,
        orElse: () => DepartmentModel(id: '', name: '', icon: Icons.help),
      );
      if (department.name.isNotEmpty) names.add(department.name);
    }
    if (names.isEmpty) return '—';
    if (names.length == 1) return names.first;
    return 'Несколько отделов';
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
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(requestStateProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final establishmentName = settings.establishmentName;
    final allProducts = settings.products;
    final allCategories = settings.categories;
    final allDepartments = settings.departments;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = _generateText(
        state, establishmentName, allProducts, allCategories, allDepartments);
    final departmentLabel = _resolveDepartmentLabel(
        state, allProducts, allCategories, allDepartments);

    // Заявка попадает в историю (а значит, и в приёмку поставки) при
    // отправке или PDF — один раз на один и тот же текст.
    void saveToHistory() {
      if (state.items.isEmpty) return;
      if (ref.read(_savedRequestTextProvider) == text) return;
      ref.read(_savedRequestTextProvider.notifier).state = text;
      ref.read(historyRepositoryProvider.notifier).add(
            HistoryEntry(
              id: Ids.newId(),
              type: HistoryType.request,
              title: '${l10n.requestTitle}: $departmentLabel',
              text: text,
              createdAt: DateTime.now(),
            ),
            staffId: ref.read(authRepositoryProvider).staffId,
            // Строки заявки — по ним потом сверяется поставка.
            lines: [
              for (final i in state.items)
                DocumentLineInput(
                  productId: i.productId,
                  productName: i.productName,
                  unit: i.unit,
                  ordered: i.quantity,
                  quantity: i.quantity,
                ),
            ],
          );
    }

    void noData() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.noData),
          backgroundColor: AppColors.darkCard2,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

    final now = DateTime.now();
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Документ заявки в стеклянной карточке.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(isDark ? 0.07 : 0.65),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.9),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrbitSectionLabel(
                          'Заявка · «$establishmentName» · '
                          '${now.day} ${months[now.month - 1]}',
                          padding: const EdgeInsets.only(bottom: 10),
                        ),
                        SelectableText(
                          text,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: isDark
                                ? Colors.white.withOpacity(0.88)
                                : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OrbitPrimaryButton(
            label: 'Отправить поставщику',
            icon: Icons.send_rounded,
            onTap: () {
              if (state.items.isEmpty) return noData();
              saveToHistory();
              Share.share(text);
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OrbitGlassButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: () async {
                  if (state.items.isEmpty) return noData();
                  saveToHistory();
                  final pdfBytes = await PdfGenerator.generateRequestPdf(
                    title: l10n.requestTitle,
                    establishmentName: establishmentName,
                    department: departmentLabel,
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OrbitGlassButton(
                label: l10n.copy,
                icon: Icons.copy_rounded,
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Clipboard.setData(ClipboardData(text: text)).then((_) {
                    messenger.showSnackBar(SnackBar(
                      content: Text(l10n.copySuccess),
                      backgroundColor: AppColors.darkCard2,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  });
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            // Заявку, собранную автоматически (по остаткам iiko), нельзя
            // "отредактировать" через goBack() — у неё нет своего отдела/
            // категории (items могут быть из разных отделов), а goBack()
            // ведёт на шаг выбора категории, который в этом случае пуст.
            if (state.departmentId != null) ...[
              Expanded(
                child: OrbitGlassButton(
                  label: l10n.edit,
                  onTap: () => ref.read(requestStateProvider.notifier).goBack(),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: OrbitGlassButton(
                label: l10n.newRequest,
                onTap: () {
                  ref.read(requestStateProvider.notifier).reset();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Текст заявки, уже сохранённой в историю, — чтобы «Отправить» и «PDF»
/// подряд не создавали две одинаковые записи.
final _savedRequestTextProvider = StateProvider<String?>((_) => null);
