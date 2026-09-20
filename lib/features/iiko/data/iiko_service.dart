import 'package:dio/dio.dart';

class IikoOrganization {
  final String id;
  final String name;
  IikoOrganization({required this.id, required this.name});
}

class IikoStore {
  final String id;
  final String name;
  IikoStore({required this.id, required this.name});
}

class IikoBalanceItem {
  final String productName;
  final double amount;
  final String unit;
  IikoBalanceItem({required this.productName, required this.amount, required this.unit});
}

/// Группа товаров в номенклатуре iiko — аналог "категории" в Akyl (у iiko
/// нет понятия "отдел", поэтому при импорте пользователь сам выбирает,
/// в какой отдел Akyl попадут товары).
class IikoGroup {
  final String id;
  final String name;
  final String? parentGroupId;
  IikoGroup({required this.id, required this.name, this.parentGroupId});
}

class IikoNomenclatureProduct {
  final String id;
  final String name;
  final String? groupId;
  final String? measureUnit;
  final String? type;
  IikoNomenclatureProduct({
    required this.id,
    required this.name,
    this.groupId,
    this.measureUnit,
    this.type,
  });
}

class IikoNomenclature {
  final List<IikoGroup> groups;
  final List<IikoNomenclatureProduct> products;
  IikoNomenclature({required this.groups, required this.products});
}

class IikoService {
  static const _baseUrl = 'https://api-ru.iiko.services/api/1';
  // Dio 5.x принимает таймауты как Duration напрямую (было int/мс в 4.x).
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));

  Future<String> getAccessToken(String apiLogin) async {
    final response = await _dio.post(
      '$_baseUrl/access_token',
      data: {'apiLogin': apiLogin},
    );
    return response.data['token'] as String;
  }

  Future<List<IikoOrganization>> getOrganizations(String token) async {
    final response = await _dio.post(
      '$_baseUrl/organizations',
      data: {},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final list = response.data['organizations'] as List;
    return list.map((o) => IikoOrganization(
      id: o['id'] as String,
      name: o['name'] as String,
    )).toList();
  }

  Future<List<IikoStore>> getStores(String token, String organizationId) async {
    final response = await _dio.post(
      '$_baseUrl/entities/list',
      data: {
        'organizationId': organizationId,
        'rootType': 'Store',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final list = response.data as List;
    return list
        .where((e) => e['type'] == 'Store')
        .map((e) => IikoStore(
              id: e['id'] as String,
              name: e['name'] as String,
            ))
        .toList();
  }

  Future<List<IikoBalanceItem>> getStoreBalance(
    String token,
    String organizationId,
    List<String> storeIds,
  ) async {
    final response = await _dio.post(
      '$_baseUrl/store/balance',
      data: {
        'organizationId': organizationId,
        'storeIds': storeIds,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final list = response.data['balances'] as List? ?? [];
    return list.map((b) => IikoBalanceItem(
      productName: b['productName'] as String? ?? b['productId'].toString(),
      amount: (b['amount'] as num?)?.toDouble() ?? 0,
      unit: b['unit'] as String? ?? 'шт',
    )).toList();
  }

  /// Номенклатура (группы товаров + сами товары) для импорта в каталог
  /// Akyl. Разбор максимально защищённый: у неофициально задокументированной
  /// схемы ответа могут быть варианты по названиям полей или неожиданно
  /// отсутствующие данные — запись без id/name просто пропускается, а не
  /// валит весь импорт исключением.
  Future<IikoNomenclature> getNomenclature(
      String token, String organizationId) async {
    final response = await _dio.post(
      '$_baseUrl/nomenclature',
      data: {'organizationId': organizationId, 'startRevision': 0},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = response.data as Map<String, dynamic>;

    final groups = <IikoGroup>[];
    for (final raw in (data['groups'] as List? ?? [])) {
      try {
        final g = raw as Map<String, dynamic>;
        if (g['isDeleted'] == true) continue;
        final id = g['id'] as String?;
        final name = g['name'] as String?;
        if (id == null || name == null || name.trim().isEmpty) continue;
        groups.add(IikoGroup(
          id: id,
          name: name,
          parentGroupId: g['parentGroup'] as String?,
        ));
      } catch (_) {
        continue;
      }
    }

    final products = <IikoNomenclatureProduct>[];
    for (final raw in (data['products'] as List? ?? [])) {
      try {
        final p = raw as Map<String, dynamic>;
        if (p['isDeleted'] == true) continue;
        final id = p['id'] as String?;
        final name = p['name'] as String?;
        if (id == null || name == null || name.trim().isEmpty) continue;
        // Модификаторы/услуги — не самостоятельные складские товары для
        // заявок/инвентаризации, пропускаем их при импорте.
        final type = (p['type'] as String?)?.toLowerCase();
        if (type == 'modifier' || type == 'service') continue;
        products.add(IikoNomenclatureProduct(
          id: id,
          name: name,
          groupId: p['groupId'] as String?,
          measureUnit: p['measureUnit'] as String?,
          type: p['type'] as String?,
        ));
      } catch (_) {
        continue;
      }
    }

    return IikoNomenclature(groups: groups, products: products);
  }
}

/// Демо-режим — тестовые данные без реального iiko-аккаунта

List<IikoBalanceItem> getDemoBalances() {
  return [
    IikoBalanceItem(productName: 'Кофе зерновой', amount: 0.8, unit: 'кг'),
    IikoBalanceItem(productName: 'Молоко', amount: 2.5, unit: 'л'),
    IikoBalanceItem(productName: 'Сироп карамель', amount: 150, unit: 'мл'),
    IikoBalanceItem(productName: 'Сироп ваниль', amount: 80, unit: 'мл'),
    IikoBalanceItem(productName: 'Стаканы 0.3', amount: 12, unit: 'шт'),
    IikoBalanceItem(productName: 'Стаканы 0.4', amount: 5, unit: 'шт'),
    IikoBalanceItem(productName: 'Крышки', amount: 30, unit: 'шт'),
    IikoBalanceItem(productName: 'Сахар', amount: 0.3, unit: 'кг'),
    IikoBalanceItem(productName: 'Чай Earl Grey', amount: 45, unit: 'г'),
    IikoBalanceItem(productName: 'Сливки 33%', amount: 0.5, unit: 'л'),
  ];
}
