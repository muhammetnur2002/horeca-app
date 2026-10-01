/// CRUD-методы для персонала, отделов и категорий — extension на
/// SettingsRepository. Каждое изменение применяется к состоянию в памяти
/// и записывается в базу.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';

extension SettingsRepositoryStaff on SettingsRepository {
  // ── Сотрудники ────────────────────────────────────────────────────────────
  void addStaff(String name) {
    if (name.isEmpty || data.staff.contains(name)) return;
    final id = Ids.newId();
    rememberStaffId(name, id);
    applyUpdate((s) => s.copyWith(staff: [...s.staff, name]));
    dao.upsertStaffMember(venueId: venueId, id: id, fullName: name);
  }

  void deleteStaff(String name) {
    final id = staffIdByName(name);
    forgetStaffName(name);
    applyUpdate(
        (s) => s.copyWith(staff: s.staff.where((x) => x != name).toList()));
    if (id != null) dao.deleteStaffMember(id);
  }

  void updateStaff(String oldName, String newName) {
    if (newName.isEmpty) return;
    final id = staffIdByName(oldName);
    forgetStaffName(oldName);
    if (id != null) {
      rememberStaffId(newName, id);
      dao.upsertStaffMember(venueId: venueId, id: id, fullName: newName);
    }
    applyUpdate((s) => s.copyWith(
        staff: s.staff.map((x) => x == oldName ? newName : x).toList()));
  }

  // ── Отделы ────────────────────────────────────────────────────────────────
  void addDepartment(String name, IconData icon) {
    final d = DepartmentModel(id: Ids.newId(), name: name, icon: icon);
    applyUpdate((s) => s.copyWith(departments: [...s.departments, d]));
    dao.upsertDepartment(
        venueId: venueId,
        id: d.id,
        name: name,
        iconKey: SettingsRepository.iconKeyOf(icon),
        sortOrder: data.departments.length - 1);
  }

  void updateDepartment(String id, String newName, IconData? newIcon) {
    var index = 0;
    applyUpdate((s) => s.copyWith(
            departments: s.departments.indexed.map((e) {
          final d = e.$2;
          if (d.id == id) {
            index = e.$1;
            return DepartmentModel(
                id: d.id, name: newName, icon: newIcon ?? d.icon);
          }
          return d;
        }).toList()));
    final d = data.departments.where((d) => d.id == id);
    if (d.isEmpty) return;
    dao.upsertDepartment(
        venueId: venueId,
        id: id,
        name: newName,
        iconKey: SettingsRepository.iconKeyOf(d.first.icon),
        sortOrder: index);
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
    // В базе отдел удаляется вместе с категориями и их товарами.
    dao.deleteDepartment(id);
  }

  // ── Категории ─────────────────────────────────────────────────────────────
  void addCategory(String name, String departmentId,
      {bool isDessertCategory = false}) {
    addCategoryWithId(Ids.newId(), name, departmentId,
        isDessertCategory: isDessertCategory);
  }

  /// Вариант addCategory с явным id — для массового импорта (iiko).
  String addCategoryWithId(String id, String name, String departmentId,
      {bool isDessertCategory = false}) {
    final c = CategoryModel(
        id: id,
        name: name,
        departmentId: departmentId,
        isDessertCategory: isDessertCategory);
    applyUpdate((s) => s.copyWith(categories: [...s.categories, c]));
    _saveCategory(c, sortOrder: data.categories.length - 1);
    return id;
  }

  void updateCategory(String id, String newName,
      {String? newDepartmentId, bool? isDessertCategory}) {
    CategoryModel? updated;
    applyUpdate((s) => s.copyWith(
            categories: s.categories.map((c) {
          if (c.id == id) {
            return updated = CategoryModel(
                id: c.id,
                name: newName,
                departmentId: newDepartmentId ?? c.departmentId,
                isDessertCategory: isDessertCategory ?? c.isDessertCategory);
          }
          return c;
        }).toList()));
    if (updated != null) _saveCategory(updated!);
  }

  void deleteCategory(String id) {
    applyUpdate((s) => s.copyWith(
        categories: s.categories.where((c) => c.id != id).toList(),
        products: s.products.where((p) => p.categoryId != id).toList()));
    // В базе категория удаляется вместе с товарами.
    dao.deleteCategory(id);
  }

  void _saveCategory(CategoryModel c, {int? sortOrder}) {
    dao.upsertCategory(
      venueId: venueId,
      id: c.id,
      name: c.name,
      departmentId: c.departmentId.isEmpty ? null : c.departmentId,
      isDessert: c.isDessertCategory,
      sortOrder: sortOrder,
    );
  }
}
