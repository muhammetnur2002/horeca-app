/// Распознавание накладных и чеков через Gemini 2.5 Flash (Google AI).
///
/// Фото уходит напрямую в Gemini API с ключом, который владелец заведения
/// вводит в Настройках; ключ хранится в защищённом хранилище телефона.
/// Модель возвращает строгий JSON по схеме — разбор в RecognizedDocument.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:horeca_app/features/stock/domain/recognized_document.dart';

/// Понятная пользователю ошибка распознавания.
class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => message;
}

/// Ключ Gemini API в защищённом хранилище.
class GeminiKeyStore {
  static const _key = 'gemini_api_key';
  static const _storage = FlutterSecureStorage();

  Future<String?> read() async {
    try {
      final v = await _storage.read(key: _key);
      return (v == null || v.trim().isEmpty) ? null : v.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key) => _storage.write(key: _key, value: key.trim());
  Future<void> delete() => _storage.delete(key: _key);
}

class GeminiInvoiceService {
  static const model = 'gemini-2.5-flash';
  static const _base = 'https://generativelanguage.googleapis.com/v1beta';

  final Dio _dio;
  final GeminiKeyStore _keys;

  GeminiInvoiceService({Dio? dio, GeminiKeyStore? keys})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 90),
            )),
        _keys = keys ?? GeminiKeyStore();

  Future<bool> hasKey() async => (await _keys.read()) != null;

  static const _prompt = '''
Ты распознаёшь фото бумажной накладной или кассового чека от поставщика
кафе/ресторана/магазина. Верни только JSON по схеме.
- items: каждая товарная строка документа. name — название как написано,
  без кода и артикула; quantity — количество числом; unit — единица
  (шт, кг, л, уп и т.п.), если указана; price — цена за единицу; sum — сумма строки.
- Не включай итоговые строки, НДС, скидки, доставку, если это не товар.
- Числа: точка как разделитель, без пробелов и знаков валют.
- kind: "накладная", "чек" или "другое". date в формате YYYY-MM-DD, если есть.
- Если поле не видно — не выдумывай, оставь пустым.''';

  static final _schema = {
    'type': 'OBJECT',
    'properties': {
      'kind': {
        'type': 'STRING',
        'enum': ['накладная', 'чек', 'другое'],
      },
      'supplier': {'type': 'STRING'},
      'number': {'type': 'STRING'},
      'date': {'type': 'STRING'},
      'total': {'type': 'NUMBER'},
      'items': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'quantity': {'type': 'NUMBER'},
            'unit': {'type': 'STRING'},
            'price': {'type': 'NUMBER'},
            'sum': {'type': 'NUMBER'},
          },
          'required': ['name', 'quantity'],
        },
      },
    },
    'required': ['kind', 'items'],
  };

  /// Распознаёт фото. Бросает [GeminiException] с понятным текстом.
  Future<RecognizedDocument> recognize(
    Uint8List image, {
    String mimeType = 'image/jpeg',
  }) async {
    final key = await _keys.read();
    if (key == null) {
      throw const GeminiException(
          'Не задан ключ Gemini API — Настройки → Приложение → '
          'Распознавание накладных.');
    }
    final Response<dynamic> res;
    try {
      res = await _dio.post(
        '$_base/models/$model:generateContent',
        options: Options(
          headers: {'x-goog-api-key': key},
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': _prompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Encode(image),
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0,
            'responseMimeType': 'application/json',
            'responseSchema': _schema,
          },
        },
      );
    } on DioException catch (e) {
      throw GeminiException(e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionTimeout
          ? 'Gemini долго не отвечает. Проверьте интернет и попробуйте ещё раз.'
          : 'Нет связи с Gemini. Проверьте интернет.');
    }
    return parseResponse(res.statusCode ?? 0, res.data);
  }

  /// Разбор ответа API (вынесен для тестов).
  static RecognizedDocument parseResponse(int status, Object? body) {
    String apiMessage() {
      if (body is Map && body['error'] is Map) {
        return (body['error']['message'] ?? '').toString();
      }
      return '';
    }

    if (status == 400 && apiMessage().toLowerCase().contains('api key')) {
      throw const GeminiException('Ключ Gemini API не подходит — проверьте его в Настройках.');
    }
    if (status == 401 || status == 403) {
      throw const GeminiException(
          'Gemini отказал в доступе: ключ неверный или API недоступен в вашей стране.');
    }
    if (status == 429) {
      throw const GeminiException(
          'Превышен лимит запросов Gemini. Подождите минуту и попробуйте снова.');
    }
    if (status != 200 || body is! Map) {
      throw GeminiException('Gemini вернул ошибку ($status). ${apiMessage()}'.trim());
    }
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiException('Gemini не смог прочитать фото. Сфотографируйте ровнее и при хорошем свете.');
    }
    final parts = (candidates.first as Map)['content']?['parts'];
    final text = parts is List && parts.isNotEmpty ? parts.first['text'] : null;
    if (text is! String) {
      throw const GeminiException('Пустой ответ Gemini.');
    }
    try {
      final json = jsonDecode(text);
      return RecognizedDocument.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      throw const GeminiException('Не удалось разобрать ответ Gemini. Попробуйте ещё раз.');
    }
  }

  /// Проверка ключа: запрос описания модели.
  Future<String?> checkKey(String key) async {
    try {
      final res = await _dio.get(
        '$_base/models/$model',
        options: Options(
            headers: {'x-goog-api-key': key.trim()},
            validateStatus: (_) => true),
      );
      if (res.statusCode == 200) return null;
      if (res.statusCode == 400 || res.statusCode == 403) {
        return 'Ключ не подходит или Gemini недоступен в вашей стране.';
      }
      return 'Ошибка проверки (${res.statusCode}).';
    } on DioException {
      return 'Нет связи с Gemini. Проверьте интернет.';
    }
  }
}

final geminiKeyStoreProvider = Provider((_) => GeminiKeyStore());

final geminiInvoiceServiceProvider = Provider(
    (ref) => GeminiInvoiceService(keys: ref.watch(geminiKeyStoreProvider)));
