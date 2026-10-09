/// Ядро настроек заведения: отделы, категории, товары, сотрудники, валюта,
/// лого. CRUD-методы для персонала/отделов/категорий и для товаров вынесены
/// в settings_repository_staff.dart и settings_repository_products.dart
/// (extension на SettingsRepository) — здесь остаётся только состояние,
/// загрузка/сохранение и публичные data/applyUpdate(), которыми эти
/// extension-методы пользуются (state из StateNotifier — protected,
/// extension не является подклассом и не может обратиться к нему напрямую).
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';

class SettingsData {
  final List<DepartmentModel> departments;
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final String establishmentName;
  final List<String> staff;
  final String currency;
  final String? logoPath;
  final bool showShiftDesserts;

  const SettingsData({
    required this.departments,
    required this.categories,
    required this.products,
    this.establishmentName = 'Спартак',
    this.staff = const ['Настя', 'Никита', 'Медина', 'Бэлла', 'Альбина'],
    this.currency = '₸',
    this.logoPath,
    this.showShiftDesserts = true,
  });

  SettingsData copyWith({
    List<DepartmentModel>? departments,
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    String? establishmentName,
    List<String>? staff,
    String? currency,
    String? logoPath,
    bool clearLogo = false,
    bool? showShiftDesserts,
  }) {
    return SettingsData(
      departments: departments ?? this.departments,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      establishmentName: establishmentName ?? this.establishmentName,
      staff: staff ?? this.staff,
      currency: currency ?? this.currency,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      showShiftDesserts: showShiftDesserts ?? this.showShiftDesserts,
    );
  }

  factory SettingsData.initial() {
    return SettingsData(
      departments: [
        DepartmentModel(id: '1', name: 'Кухня', icon: Icons.kitchen),
        DepartmentModel(id: '2', name: 'Бар', icon: Icons.local_bar),
        DepartmentModel(id: '3', name: 'Зал', icon: Icons.table_restaurant),
        DepartmentModel(id: '4', name: 'Склад', icon: Icons.warehouse),
        DepartmentModel(
            id: '5', name: 'Клининг', icon: Icons.cleaning_services),
      ],
      categories: [
        CategoryModel(id: '1', name: 'Продукты', departmentId: '1'),
        CategoryModel(id: '2', name: 'Заморозка', departmentId: '1'),
        CategoryModel(id: '3', name: 'Хозтовары', departmentId: '1'),
        CategoryModel(id: '4', name: 'Напитки', departmentId: '2'),
        CategoryModel(id: '5', name: 'Кофе', departmentId: '2'),
        CategoryModel(id: '6', name: 'Сиропы', departmentId: '2'),
        CategoryModel(
            id: '7',
            name: 'Десерты',
            departmentId: '2',
            isDessertCategory: true),
        CategoryModel(id: '8', name: 'Хозтовары', departmentId: '2'),
        CategoryModel(id: '9', name: 'Упаковка', departmentId: '3'),
        CategoryModel(id: '10', name: 'Хозтовары', departmentId: '3'),
      ],
      products: [
        ProductModel(id: '1', name: 'Томаты', unit: 'кг', categoryId: '1'),
        ProductModel(id: '2', name: 'Сыр', unit: 'кг', categoryId: '1'),
        ProductModel(
            id: '3',
            name: 'Замороженные овощи',
            unit: 'упаковка',
            categoryId: '2'),
        ProductModel(
            id: '4', name: 'Моющее средство', unit: 'шт', categoryId: '3'),
        ProductModel(id: '5', name: 'Кола', unit: 'л', categoryId: '4'),
        ProductModel(
            id: '6', name: 'Кофе зерновой', unit: 'кг', categoryId: '5'),
        ProductModel(
            id: '7', name: 'Сироп клубничный', unit: 'мл', categoryId: '6'),
        ProductModel(id: '8', name: 'Чизкейк', unit: 'шт', categoryId: '7'),
        ProductModel(
            id: '9',
            name: 'Пакеты бумажные',
            unit: 'упаковка',
            categoryId: '9'),
        ProductModel(id: '10', name: 'Салфетки', unit: 'шт', categoryId: '10'),
      ],
      establishmentName: 'Спартак',
      staff: ['Настя', 'Никита', 'Медина', 'Бэлла', 'Альбина'],
      currency: '₸',
    );
  }
}

// Восстанавливает иконку отдела из сохранённого codePoint при загрузке из
// SharedPreferences. Раньше это делалось через `IconData(int.parse(...))`
// напрямую — не-константный вызов IconData, из-за чего release-сборка
// (`flutter build apk --release`) падала на шаге tree-shaking иконок:
// "cannot tree shake icon fonts" (см. проверку в CI). В приложении нет
// экрана выбора произвольной иконки — новые отделы всегда получают
// Icons.category (см. addDepartment в settings_repository_staff.dart),
// а начальный набор — фиксированный список ниже, так что достаточно
// таблицы соответствия на этих константах.
IconData _iconForCodePoint(int codePoint) {
  const known = [
    Icons.kitchen,
    Icons.local_bar,
    Icons.table_restaurant,
    Icons.warehouse,
    Icons.cleaning_services,
    Icons.category,
    Icons.help,
  ];
  for (final icon in known) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.category;
}

class SettingsRepository extends StateNotifier<SettingsData> {
  final SharedPreferences _prefs;
  final String _settingsKey;
  final VoidCallback? _onChanged;

  SettingsRepository(this._prefs, String venueCode, {VoidCallback? onChanged})
      : _settingsKey = 'settings_data${venueKeySuffix(venueCode)}',
        _onChanged = onChanged,
        super(SettingsData.initial()) {
    _loadFromPrefs();
  }

  /// Текущие данные — публичный доступ для extension-методов в
  /// settings_repository_staff.dart / settings_repository_products.dart.
  SettingsData get data => state;

  /// Общая точка входа для extension-методов: применяет изменение и сразу
  /// сохраняет (state из StateNotifier — protected, extension-методы не
  /// могут менять его напрямую).
  void applyUpdate(SettingsData Function(SettingsData current) update) {
    state = update(state);
    persistToPrefs();
  }

  void persistToPrefs() {
    final data = {
      'departments': state.departments
          .map((d) =>
              {'id': d.id, 'name': d.name, 'icon': d.icon.codePoint.toString()})
          .toList(),
      'categories': state.categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'departmentId': c.departmentId,
                'isDessertCategory': c.isDessertCategory,
              })
          .toList(),
      'products': state.products
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'unit': p.unit,
                'inventoryUnit': p.inventoryUnit,
                'categoryId': p.categoryId,
                'minStock': p.minStock,
              })
          .toList(),
      'establishmentName': state.establishmentName,
      'staff': state.staff,
      'currency': state.currency,
      'logoPath': state.logoPath,
      'showShiftDesserts': state.showShiftDesserts,
    };
    _prefs.setString(_settingsKey, jsonEncode(data));
    // Мгновенная (с коротким дебаунсом) отправка в облако по аккаунту —
    // см. cloud_auto_sync.dart. Ничего не делает, если не залогинены.
    _onChanged?.call();
  }

  void _loadFromPrefs() {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) return;
    try {
      final data = jsonDecode(jsonString);
      final depts = (data['departments'] as List)
          .map((d) => DepartmentModel(
                id: d['id'],
                name: d['name'],
                icon: _iconForCodePoint(int.parse(d['icon'])),
              ))
          .toList();
      final cats = (data['categories'] as List)
          .map((c) => CategoryModel(
                id: c['id'],
                name: c['name'],
                departmentId: c['departmentId'],
                // Обратная совместимость: в старых сохранённых данных этого
                // поля не было — тогда один раз подстраховываемся по названию
                // (содержит "десерт"), дальше это уже явный флаг и от
                // названия больше не зависит.
                isDessertCategory: c['isDessertCategory'] as bool? ??
                    (c['name'] as String).toLowerCase().contains('десерт'),
              ))
          .toList();
      final prods = (data['products'] as List)
          .map((p) => ProductModel(
                id: p['id'],
                name: p['name'],
                unit: p['unit'],
                inventoryUnit: p['inventoryUnit'] ?? p['unit'],
                categoryId: p['categoryId'],
                minStock: (p['minStock'] as num?)?.toDouble(),
              ))
          .toList();
      final name = data['establishmentName'] as String? ?? 'Спартак';
      final currency = data['currency'] as String? ?? '₸';
      final logoPath = data['logoPath'] as String?;
      final showShiftDesserts = data['showShiftDesserts'] as bool? ?? true;
      List<String> staff;
      try {
        staff = data['staff'] != null
            ? List<String>.from(data['staff'] as List)
            : ['Настя', 'Никита', 'Медина', 'Бэлла', 'Альбина'];
      } catch (_) {
        staff = ['Настя', 'Никита', 'Медина', 'Бэлла', 'Альбина'];
      }
      state = SettingsData(
        departments: depts,
        categories: cats,
        products: prods,
        establishmentName: name,
        staff: staff,
        currency: currency,
        logoPath: logoPath,
        showShiftDesserts: showShiftDesserts,
      );
    } catch (_) {}
  }

  // ── Десерты на закрытии смены (можно скрыть, если не нужны) ────────────────
  void setShowShiftDesserts(bool value) {
    state = state.copyWith(showShiftDesserts: value);
    persistToPrefs();
  }

  // ── Сброс всех данных ─────────────────────────────────────────────────────
  void resetAll() {
    state = state.copyWith(
      categories: [],
      products: [],
      staff: [],
    );
    persistToPrefs();
  }

  // ── Лого заведения ───────────────────────────────────────────────────────
  void setLogoPath(String path) {
    state = state.copyWith(logoPath: path);
    persistToPrefs();
  }

  void removeLogo() {
    state = state.copyWith(clearLogo: true);
    persistToPrefs();
  }

  // ── Валюта ────────────────────────────────────────────────────────────────
  void setCurrency(String currency) {
    state = state.copyWith(currency: currency);
    persistToPrefs();
  }
}

final settingsRepositoryProvider =
    StateNotifierProvider<SettingsRepository, SettingsData>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final venueCode = ref.watch(venueRepositoryProvider).activeVenueCode;
  return SettingsRepository(prefs, venueCode,
      onChanged: () => ref.read(cloudAutoSyncProvider).scheduleSync());
});
