/// Ядро настроек заведения: отделы, категории, товары, сотрудники, валюта,
/// лого. CRUD-методы для персонала/отделов/категорий и для товаров вынесены
/// в settings_repository_staff.dart и settings_repository_products.dart
/// (extension на SettingsRepository).
///
/// Данные хранятся в локальной базе. Состояние в памяти — кэш для
/// синхронных обращений экранов: при создании репозиторий загружает
/// данные заведения из базы, а каждое изменение сразу применяется
/// к состоянию и записывается в базу.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/shared/models/department_icons.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

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
    this.establishmentName = 'Моё заведение',
    this.staff = const [],
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

  /// Пустое заведение — без демонстрационных данных.
  factory SettingsData.empty() =>
      const SettingsData(departments: [], categories: [], products: []);
}

class SettingsRepository extends StateNotifier<SettingsData> {
  final CatalogDao _dao;

  /// id заведения в базе — для extension-методов.
  final String venueId;

  /// Сотрудники в состоянии хранятся именами (так их показывают экраны),
  /// а в базе — строками с id. Карта нужна для переименования/удаления.
  final Map<String, String> _staffIdByName = {};

  bool _loaded = false;
  bool get isLoaded => _loaded;

  SettingsRepository(this._dao, this.venueId) : super(SettingsData.empty()) {
    _ready = _load();
  }

  late final Future<void> _ready;

  /// Завершается, когда данные загружены из базы.
  Future<void> get ready => _ready;

  /// Доступ к базе для extension-методов.
  CatalogDao get dao => _dao;

  /// Текущие данные — публичный доступ для extension-методов.
  SettingsData get data => state;

  /// Применяет изменение к состоянию (запись в базу делает вызывающий).
  void applyUpdate(SettingsData Function(SettingsData current) update) {
    state = update(state);
  }

  String? staffIdByName(String name) => _staffIdByName[name];
  void rememberStaffId(String name, String id) => _staffIdByName[name] = id;
  void forgetStaffName(String name) => _staffIdByName.remove(name);

  Future<void> _load() async {
    final venues = await _dao.loadVenues();
    final venue = venues.where((v) => v.id == venueId);
    final departments = await _dao.loadDepartments(venueId);
    final categories = await _dao.loadCategories(venueId);
    final products = await _dao.loadProducts(venueId);
    final staff = await _dao.loadStaff(venueId);
    if (!mounted) return;

    _staffIdByName
      ..clear()
      ..addEntries(staff.map((s) => MapEntry(s.fullName, s.id)));

    state = SettingsData(
      departments: departments
          .map((d) => DepartmentModel(
                id: d.id,
                name: d.name,
                icon: DepartmentIcons.resolve(d.iconKey),
              ))
          .toList(),
      categories: categories
          .map((c) => CategoryModel(
                id: c.id,
                name: c.name,
                departmentId: c.departmentId ?? '',
                isDessertCategory: c.isDessert,
              ))
          .toList(),
      products: products
          .map((p) => ProductModel(
                id: p.id,
                name: p.name,
                unit: p.unit,
                inventoryUnit: p.inventoryUnit,
                categoryId: p.categoryId ?? '',
                minStock: p.minStock,
                iikoProductId: p.iikoProductId,
              ))
          .toList(),
      establishmentName:
          venue.isEmpty ? 'Моё заведение' : venue.first.reportName,
      staff: staff.map((s) => s.fullName).toList(),
      currency: venue.isEmpty ? '₸' : venue.first.currency,
      logoPath: venue.isEmpty ? null : venue.first.logoPath,
      showShiftDesserts: venue.isEmpty ? true : venue.first.showShiftDesserts,
    );
    _loaded = true;
  }

  // ── Десерты на закрытии смены (можно скрыть, если не нужны) ────────────────
  void setShowShiftDesserts(bool value) {
    state = state.copyWith(showShiftDesserts: value);
    _dao.updateVenue(venueId, showShiftDesserts: value);
  }

  // ── Сброс справочников ────────────────────────────────────────────────────
  void resetAll() {
    for (final c in state.categories) {
      _dao.deleteCategory(c.id);
    }
    for (final p in state.products) {
      _dao.deleteProduct(p.id);
    }
    for (final id in _staffIdByName.values) {
      _dao.deleteStaffMember(id);
    }
    _staffIdByName.clear();
    state = state.copyWith(categories: [], products: [], staff: []);
  }

  // ── Лого заведения ───────────────────────────────────────────────────────
  void setLogoPath(String path) {
    state = state.copyWith(logoPath: path);
    _dao.updateVenue(venueId, logoPath: path);
  }

  void removeLogo() {
    state = state.copyWith(clearLogo: true);
    _dao.updateVenue(venueId, clearLogo: true);
  }

  // ── Валюта ────────────────────────────────────────────────────────────────
  void setCurrency(String currency) {
    state = state.copyWith(currency: currency);
    _dao.updateVenue(venueId, currency: currency);
  }

  // ── Название для отчётов ──────────────────────────────────────────────────
  void setEstablishmentName(String name) {
    state = state.copyWith(establishmentName: name);
    _dao.updateVenue(venueId, reportName: name);
  }

  /// Ключ иконки для записи в базу.
  static String iconKeyOf(IconData icon) => DepartmentIcons.keyOf(icon);
}

final settingsRepositoryProvider =
    StateNotifierProvider<SettingsRepository, SettingsData>((ref) {
  return SettingsRepository(
    ref.watch(catalogDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});
