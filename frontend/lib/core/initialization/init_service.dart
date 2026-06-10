import 'package:flutter/material.dart';
import 'package:horeca_app/core/network/api_client.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

Future<void> initFromServer(ApiClient api, SettingsRepository repo) async {
  try {
    final deptJson = await api.getDepartments();
    final catJson = await api.getCategories();
    final prodJson = await api.getProducts();

    final departments = deptJson.map((d) => DepartmentModel(
      id: d['id'] as String,
      name: d['name'] as String,
      icon: Icons.category, // сервер пока не хранит иконку
    )).toList();

    final categories = catJson.map((c) => CategoryModel(
      id: c['id'] as String,
      name: c['name'] as String,
      departmentId: c['departmentId'] as String,
    )).toList();

    final products = prodJson.map((p) => ProductModel(
      id: p['id'] as String,
      name: p['name'] as String,
      unit: p['unit'] as String,
      categoryId: p['categoryId'] as String,
    )).toList();

    // Заменяем локальные данные серверными (если они пришли)
    if (departments.isNotEmpty || categories.isNotEmpty || products.isNotEmpty) {
      repo.replaceAll(departments, categories, products);
    }
  } catch (e) {
    debugPrint('Не удалось загрузить данные с сервера: $e');
    // Остаёмся на локальных данных
  }
}