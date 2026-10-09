import 'dart:math';

import 'package:dio/dio.dart';
import 'package:horeca_app/features/supply/data/gigachat_dio.dart';
import 'package:horeca_app/features/supply/domain/invoice_parse.dart';
import 'package:horeca_app/features/supply/domain/supply_models.dart';

class GigaChatException implements Exception {
  final String message;
  const GigaChatException(this.message);
  @override
  String toString() => message;
}

/// Распознавание накладной через GigaChat-2-Max.
/// Ключ приходит снаружи, в код он не зашит.
///
/// Сертификат шлюза Сбера подписан российским корневым УЦ. На части телефонов
/// его нет в системном хранилище, поэтому проверка ослаблена только для
/// двух хостов GigaChat.
class GigaChatClient {
  final Dio _dio;
  static const model = 'GigaChat-2-Max';

  GigaChatClient({Dio? dio}) : _dio = dio ?? buildGigaChatDio();

  Future<List<SupplyLine>> recognizeInvoice({
    required String authorizationKey,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final token = await _accessToken(authorizationKey);
    final fileId = await _upload(token, imageBytes, fileName);
    final response = await _dio.post(
      'https://api.giga.chat/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }),
      data: {
        'model': model,
        'temperature': 0.1,
        'stream': false,
        'messages': [
          {
            'role': 'user',
            'attachments': [fileId],
            'content': 'Это фото или скан накладной на товары для кафе. '
                'Верни только JSON-массив без пояснений. '
                'Каждый элемент: {"name":"название","qty":число,"unit":"кг|л|шт|г|мл"}. '
                'Бери количество, которое приехало. Пропусти итоги, НДС и пустые строки.',
          },
        ],
      },
    );
    final data = response.data;
    final choices = data is Map ? data['choices'] : null;
    if (choices is! List || choices.isEmpty) {
      throw const GigaChatException('GigaChat не вернул ответ. Введите накладную вручную.');
    }
    final message = choices.first is Map ? choices.first['message'] : null;
    final content = message is Map ? message['content'] : null;
    final text = content is String ? content : '$content';
    try {
      return parseInvoiceTable(text);
    } on FormatException {
      throw const GigaChatException(
        'Накладную не удалось прочитать. Введите строки вручную.',
      );
    }
  }

  Future<String> _accessToken(String authorizationKey) async {
    try {
      final response = await _dio.post(
        'https://ngw.devices.sberbank.ru:9443/api/v2/oauth',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': 'Basic $authorizationKey',
            'RqUID': _rqUid(),
            'Accept': 'application/json',
          },
        ),
        data: {'scope': 'GIGACHAT_API_PERS'},
      );
      final token = response.data is Map ? response.data['access_token'] : null;
      if (token is! String || token.isEmpty) {
        throw const GigaChatException('GigaChat не выдал доступ. Проверьте ключ в настройках.');
      }
      return token;
    } on GigaChatException {
      rethrow;
    } on DioException catch (error) {
      throw GigaChatException(_dioMessage(error, 'Не удалось войти в GigaChat. Проверьте ключ и сеть.'));
    }
  }

  Future<String> _upload(String token, List<int> bytes, String fileName) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'purpose': 'general',
      });
      final response = await _dio.post(
        'https://api.giga.chat/v1/files',
        data: form,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final id = response.data is Map ? response.data['id'] : null;
      if (id is! String || id.isEmpty) {
        throw const GigaChatException('GigaChat не принял фото. Введите накладную вручную.');
      }
      return id;
    } on GigaChatException {
      rethrow;
    } on DioException catch (error) {
      throw GigaChatException(_dioMessage(error, 'Фото не отправилось. Введите накладную вручную.'));
    }
  }

  String _dioMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    return fallback;
  }

  String _rqUid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
