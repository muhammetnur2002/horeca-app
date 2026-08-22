/// CRUD-методы для персонала, названия заведения, отделов и категорий —
/// extension на SettingsRepository. Вынесены из settings_repository.dart,
/// чтобы не раздувать его; работают через публичные data/applyUpdate()
/// (state из StateNotifier — protected, extension-методы не могут его
/// использовать напрямую, т.к. extension не является подклассом).
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';

extension SettingsRepositoryStaff on SettingsRepository {
  // ── Сотрудники ────────────────────────────────────────────────────────────
  void addStaff(String name) {
    if (name.isEmpty || data.staff.contains(name)) return;
    applyUpdate((s) => s.copyWith(staff: [...s.staff, name]));
  }

  void deleteStaff(String name) {
    applyUpdate(
        (s) => s.copyWith(staff: s.staff.where((x) => x != name).toList()));
  }

  void updateStaff(String oldName, String newName) {
    if (newName.isEmpty) return;
    applyUpdate((s) => s.copyWith(
        staff: s.staff.map((x) => x == oldName ? newName : x).toList()));
  }

  // ── Заведение ─────────────────────────────────────────────────────────────
  void setEstablishmentName(String name) {
    applyUpdate((s) => s.copyWith(establishmentName: name));
  }

  // ── Отделы ────────────────────────────────────────────────────────────────
  void addDepartment(String name, IconData icon) {
    final d = DepartmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: icon);
    applyUpdate((s) => s.copyWith(departments: [...s.departments, d]));
  }

  void updateDepartment(String id, String newName, IconData? newIcon) {
    applyUpdate((s) => s.copyWith(
            departments: s.departments.map((d) {
          if (d.id == id) {
            return DepartmentModel(
                id: d.id, name: newName, icon: newIcon ?? d.icon);
          }
          return d;
        }).toList()));
  }

  void deleteDepartment(String id) {
    applyUpdate((s) => s.copyWith(
        departments: s.departments.where((d) => d.id != id).toList(),
        categories: s.categories.where((c) => c.departmentId != id).toList(),
        products: s.products.where((p) {
          final cat = s.categories.firstWhere((c) => c.id == p.categoryId,
              orElse: () => CategoryModel(id: '', name: '', departmentId: ''));
          return cat.departmentId != id;
        }).toList()));
  }

  // ── Категории ─────────────────────────────────────────────────────────────
  void addCategory(String name, String departmentId,
      {bool isDessertCategory = false}) {
    final c = CategoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        departmentId: departmentId,
        isDessertCategory: isDessertCategory);
    applyUpdate((s) => s.copyWith(categories: [...s.categories, c]));
  }

  void updateCategory(String id, String newName,
      {String? newDepartmentId, bool? isDessertCategory}) {
    applyUpdate((s) => s.copyWith(
            categories: s.categories.map((c) {
          if (c.id == id) {
            return CategoryModel(
                id: c.id,
                name: newName,
                departmentId: newDepartmentId ?? c.departmentId,
                isDessertCategory: isDessertCategory ?? c.isDessertCategory);
          }
          return c;
        }).toList()));
  }

  void deleteCategory(String id) {
    applyUpdate((s) => s.copyWith(
        categories: s.categories.where((c) => c.id != id).toList(),
        products: s.products.where((p) => p.categoryId != id).toList()));
  }
}
