/// Формирование текста заявки (шаг 3): приветствие, форматирование чисел и
/// сборка текста, сгруппированного по отделам/категориям. Вынесены из
/// generate_step.dart, чтобы не раздувать его build().
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

String requestGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 6 && hour < 12) return 'Доброе утро!';
  if (hour >= 12 && hour < 18) return 'Добрый день!';
  return 'Добрый вечер!';
}

String formatRequestQuantity(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String generateRequestText(
  RequestState state,
  String establishmentName,
  List<ProductModel> allProducts,
  List<CategoryModel> allCategories,
  List<DepartmentModel> allDepartments,
) {
  final buffer = StringBuffer();
  buffer.writeln(requestGreeting());
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
            '- ${item.productName} — ${formatRequestQuantity(item.quantity)} ${item.unit}');
      }
      buffer.writeln();
    }
  }
  buffer.writeln('Спасибо!');
  return buffer.toString();
}
