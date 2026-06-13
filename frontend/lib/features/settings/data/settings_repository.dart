import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

class SettingsData {
  final List<DepartmentModel> departments;
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final String establishmentName;

  const SettingsData({
    required this.departments,
    required this.categories,
    required this.products,
    this.establishmentName = 'Sunrise',
  });

  SettingsData copyWith({
    List<DepartmentModel>? departments,
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    String? establishmentName,
  }) {
    return SettingsData(
      departments: departments ?? this.departments,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      establishmentName: establishmentName ?? this.establishmentName,
    );
  }

  factory SettingsData.initial() {
    return SettingsData(
      departments: [
        DepartmentModel(id: '1', name: 'Кухня', icon: Icons.kitchen),
        DepartmentModel(id: '2', name: 'Бар', icon: Icons.local_bar),
        DepartmentModel(id: '3', name: 'Зал', icon: Icons.table_restaurant),
        DepartmentModel(id: '4', name: 'Склад', icon: Icons.warehouse),
        DepartmentModel(id: '5', name: 'Клининг', icon: Icons.cleaning_services),
      ],
      categories: [
        CategoryModel(id: '1', name: 'Продукты', departmentId: '1'),
        CategoryModel(id: '2', name: 'Заморозка', departmentId: '1'),
        CategoryModel(id: '3', name: 'Хозтовары', departmentId: '1'),
        CategoryModel(id: '4', name: 'Напитки', departmentId: '2'),
        CategoryModel(id: '5', name: 'Кофе', departmentId: '2'),
        CategoryModel(id: '6', name: 'Сиропы', departmentId: '2'),
        CategoryModel(id: '7', name: 'Десерты', departmentId: '2'),
        CategoryModel(id: '8', name: 'Хозтовары', departmentId: '2'),
        CategoryModel(id: '9', name: 'Упаковка', departmentId: '3'),
        CategoryModel(id: '10', name: 'Хозтовары', departmentId: '3'),
      ],
      products: [
        ProductModel(id: '1', name: 'Томаты', unit: 'кг', categoryId: '1'),
        ProductModel(id: '2', name: 'Сыр', unit: 'кг', categoryId: '1'),
        ProductModel(id: '3', name: 'Замороженные овощи', unit: 'упаковка', categoryId: '2'),
        ProductModel(id: '4', name: 'Моющее средство', unit: 'шт', categoryId: '3'),
        ProductModel(id: '5', name: 'Кола', unit: 'л', categoryId: '4'),
        ProductModel(id: '6', name: 'Кофе зерновой', unit: 'кг', categoryId: '5'),
        ProductModel(id: '7', name: 'Сироп клубничный', unit: 'мл', categoryId: '6'),
        ProductModel(id: '8', name: 'Чизкейк', unit: 'шт', categoryId: '7'),
        ProductModel(id: '9', name: 'Пакеты бумажные', unit: 'упаковка', categoryId: '9'),
        ProductModel(id: '10', name: 'Салфетки', unit: 'шт', categoryId: '10'),
      ],
      establishmentName: 'Sunrise',
    );
  }
}

class SettingsRepository extends StateNotifier<SettingsData> {
  final SharedPreferences _prefs;
  static const _settingsKey = 'settings_data';

  SettingsRepository(this._prefs) : super(SettingsData.initial()) {
    _loadFromPrefs();
  }

  void _saveToPrefs() {
    final data = {
      'departments': state.departments
          .map((d) => {'id': d.id, 'name': d.name, 'icon': d.icon.codePoint.toString()})
          .toList(),
      'categories': state.categories
          .map((c) => {'id': c.id, 'name': c.name, 'departmentId': c.departmentId})
          .toList(),
      'products': state.products
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'unit': p.unit,
                'inventoryUnit': p.inventoryUnit,
                'categoryId': p.categoryId,
              })
          .toList(),
      'establishmentName': state.establishmentName,
    };
    _prefs.setString(_settingsKey, jsonEncode(data));
  }

  void _loadFromPrefs() {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) return;
    try {
      final data = jsonDecode(jsonString);
      final depts = (data['departments'] as List).map((d) => DepartmentModel(
            id: d['id'],
            name: d['name'],
            icon: IconData(int.parse(d['icon']), fontFamily: 'MaterialIcons'),
          )).toList();
      final cats = (data['categories'] as List).map((c) => CategoryModel(
            id: c['id'],
            name: c['name'],
            departmentId: c['departmentId'],
          )).toList();
      final prods = (data['products'] as List).map((p) => ProductModel(
            id: p['id'],
            name: p['name'],
            unit: p['unit'],
            inventoryUnit: p['inventoryUnit'] ?? p['unit'],
            categoryId: p['categoryId'],
          )).toList();
      final name = data['establishmentName'] as String? ?? 'Sunrise';
      state = SettingsData(
        departments: depts,
        categories: cats,
        products: prods,
        establishmentName: name,
      );
    } catch (_) {}
  }

  void setEstablishmentName(String name) {
    state = state.copyWith(establishmentName: name);
    _saveToPrefs();
  }

  void addDepartment(String name, IconData icon) {
    final d = DepartmentModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, icon: icon);
    state = state.copyWith(departments: [...state.departments, d]);
    _saveToPrefs();
  }

  void updateDepartment(String id, String newName, IconData? newIcon) {
    state = state.copyWith(
      departments: state.departments.map((d) {
        if (d.id == id) return DepartmentModel(id: d.id, name: newName, icon: newIcon ?? d.icon);
        return d;
      }).toList(),
    );
    _saveToPrefs();
  }

  void deleteDepartment(String id) {
    state = state.copyWith(
      departments: state.departments.where((d) => d.id != id).toList(),
      categories: state.categories.where((c) => c.departmentId != id).toList(),
      products: state.products.where((p) {
        final cat = state.categories.firstWhere((c) => c.id == p.categoryId, orElse: () => CategoryModel(id: '', name: '', departmentId: ''));
        return cat.departmentId != id;
      }).toList(),
    );
    _saveToPrefs();
  }

  void addCategory(String name, String departmentId) {
    final c = CategoryModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, departmentId: departmentId);
    state = state.copyWith(categories: [...state.categories, c]);
    _saveToPrefs();
  }

  void updateCategory(String id, String newName, {String? newDepartmentId}) {
    state = state.copyWith(
      categories: state.categories.map((c) {
        if (c.id == id) return CategoryModel(id: c.id, name: newName, departmentId: newDepartmentId ?? c.departmentId);
        return c;
      }).toList(),
    );
    _saveToPrefs();
  }

  void deleteCategory(String id) {
    state = state.copyWith(
      categories: state.categories.where((c) => c.id != id).toList(),
      products: state.products.where((p) => p.categoryId != id).toList(),
    );
    _saveToPrefs();
  }

  void addProduct(String name, String unit, String categoryId, {String? inventoryUnit}) {
    final p = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      unit: unit,
      inventoryUnit: inventoryUnit ?? unit,
      categoryId: categoryId,
    );
    state = state.copyWith(products: [...state.products, p]);
    _saveToPrefs();
  }

  void updateProduct(String id, String newName, String newUnit, {String? newCategoryId, String? newInventoryUnit}) {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == id) {
          return ProductModel(
            id: p.id,
            name: newName,
            unit: newUnit,
            inventoryUnit: newInventoryUnit ?? p.inventoryUnit,
            categoryId: newCategoryId ?? p.categoryId,
          );
        }
        return p;
      }).toList(),
    );
    _saveToPrefs();
  }

  void deleteProduct(String id) {
    state = state.copyWith(products: state.products.where((p) => p.id != id).toList());
    _saveToPrefs();
  }

  void bulkAddProducts(List<String> names, String defaultUnit, String categoryId, {String? defaultInventoryUnit}) {
    final newProds = names.map((name) => ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString() + name,
      name: name,
      unit: defaultUnit,
      inventoryUnit: defaultInventoryUnit ?? defaultUnit,
      categoryId: categoryId,
    )).toList();
    state = state.copyWith(products: [...state.products, ...newProds]);
    _saveToPrefs();
  }
}

final settingsRepositoryProvider = StateNotifierProvider<SettingsRepository, SettingsData>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});