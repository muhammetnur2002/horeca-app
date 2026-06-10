import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(String? authToken) {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000/api/v1',
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'x-establishment-id': 'a0081dc3-e574-493b-b3a3-a18c02cdf458',
      },
      connectTimeout: const Duration(seconds: 5),
    ));
  }

  // ========== GET ==========
  Future<List<dynamic>> getDepartments() async {
    final response = await _dio.get('/departments');
    return response.data;
  }

  Future<List<dynamic>> getCategories({String? departmentId}) async {
    final params = <String, dynamic>{};
    if (departmentId != null) params['departmentId'] = departmentId;
    final response = await _dio.get('/categories', queryParameters: params);
    return response.data;
  }

  Future<List<dynamic>> getProducts({String? categoryId}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['categoryId'] = categoryId;
    final response = await _dio.get('/products', queryParameters: params);
    return response.data;
  }

  // ========== POST ==========
  Future<Map<String, dynamic>> createDepartment(String name) async {
    final response = await _dio.post('/departments', data: {'name': name});
    return response.data;
  }

  Future<Map<String, dynamic>> createCategory(String name, String departmentId) async {
    final response = await _dio.post('/categories', data: {
      'name': name,
      'departmentId': departmentId,
    });
    return response.data;
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  Future<Map<String, dynamic>> createProduct(String name, String unit, String categoryId) async {
    final response = await _dio.post('/products', data: {
      'name': name,
      'unit': unit,
      'categoryId': categoryId,
    });
    return response.data;
  }

  Future<List<dynamic>> bulkCreateProducts(List<String> names) async {
    final response = await _dio.post('/products/bulk', data: {'names': names});
    return response.data;
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  // ========== PATCH ==========
  Future<void> updateDepartment(String id, String name) async {
    await _dio.patch('/departments/$id', data: {'name': name});
  }

  Future<void> updateCategory(String id, {String? name, String? departmentId}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (departmentId != null) data['departmentId'] = departmentId;
    await _dio.patch('/categories/$id', data: data);
  }

  Future<void> updateProduct(String id, {String? name, String? unit, String? categoryId}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (unit != null) data['unit'] = unit;
    if (categoryId != null) data['categoryId'] = categoryId;
    await _dio.patch('/products/$id', data: data);
  }

  bool isUuid(String? id) {
  if (id == null) return false;
  final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  return uuidRegex.hasMatch(id);
}
}