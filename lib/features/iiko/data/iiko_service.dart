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

class IikoService {
  static const _baseUrl = 'https://api-ru.iiko.services/api/1';
  final Dio _dio = Dio();

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



