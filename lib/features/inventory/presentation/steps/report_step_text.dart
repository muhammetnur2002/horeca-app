/// Формирование текста отчёта об инвентаризации (шаг 4): название отдела и
/// сборка сгруппированного по категориям текста. Вынесены из
/// report_step.dart, чтобы не раздувать его build().
library;

import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

String deptNameForReport(String? departmentId, AppLocalizations l10n) {
  if (departmentId == 'all') return l10n.allDepartments;
  switch (departmentId) {
    case '1':
      return 'Кухня';
    case '2':
      return 'Бар';
    case '3':
      return 'Зал';
    case '4':
      return 'Склад';
    case '5':
      return 'Клининг';
    default:
      return departmentId ?? 'Неизвестный отдел';
  }
}

String generateInventoryReportText(
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
  buffer.writeln('${l10n.department}: ${deptNameForReport(state.departmentId, l10n)}');
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
