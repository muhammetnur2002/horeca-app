import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/stock/data/gemini_invoice_service.dart';
import 'package:horeca_app/features/stock/domain/product_matcher.dart';
import 'package:horeca_app/features/stock/domain/recognized_document.dart';

void main() {
  group('RecognizedDocument.fromJson', () {
    test('разбирает ответ модели, терпит числа строкой и запятую', () {
      final d = RecognizedDocument.fromJson({
        'kind': 'накладная',
        'supplier': 'ТОО «Молочный двор»',
        'number': '1245',
        'date': '2026-10-02',
        'total': '15 360,50',
        'items': [
          {'name': 'Молоко 3,2% 1л', 'quantity': '12', 'unit': 'шт', 'price': '420,5'},
          {'name': 'Сливки 33%', 'quantity': 2, 'sum': 3600},
          {'name': '', 'quantity': 3},
          {'name': 'Без количества'},
          'мусор',
        ],
      });
      expect(d.kind, 'накладная');
      expect(d.total, 15360.5);
      expect(d.items.length, 2);
      expect(d.items[0].quantity, 12);
      expect(d.items[0].unitPrice, 420.5);
      expect(d.items[1].unitPrice, 1800); // из суммы строки
    });

    test('пустой ответ не падает', () {
      final d = RecognizedDocument.fromJson({});
      expect(d.items, isEmpty);
      expect(d.kind, 'другое');
    });
  });

  group('ProductMatcher', () {
    const catalog = ['Молоко 3,2%', 'Сливки 33%', 'Кофе зерновой', 'Стаканы 0,4'];

    String? match(String s) =>
        ProductMatcher.bestMatch<String>(s, catalog, (x) => x);

    test('находит товар по длинному названию из накладной', () {
      expect(match('Молоко ультрапаст. 3,2% 1л Простоквашино'), 'Молоко 3,2%');
      expect(match('СЛИВКИ питьевые 33 % 1 л'), 'Сливки 33%');
      expect(match('Кофе в зёрнах арабика, зерновой 1 кг'), 'Кофе зерновой');
      expect(match('Стакан бумажный 0.4 л (50 шт)'), 'Стаканы 0,4');
    });

    test('не сопоставляет непохожее', () {
      expect(match('Сахар песок 1 кг'), isNull);
      expect(match('Молоко овсяное'), isNull); // нет «3,2%»
    });
  });

  group('GeminiInvoiceService.parseResponse', () {
    test('достаёт JSON из ответа модели', () {
      final d = GeminiInvoiceService.parseResponse(200, {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '{"kind":"чек","items":[{"name":"Сахар","quantity":2,"price":350}]}'}
              ]
            }
          }
        ]
      });
      expect(d.kind, 'чек');
      expect(d.items.single.name, 'Сахар');
    });

    test('понятные ошибки для ключа, лимита и пустого ответа', () {
      expect(
          () => GeminiInvoiceService.parseResponse(400, {
                'error': {'message': 'API key not valid. Please pass a valid API key.'}
              }),
          throwsA(isA<GeminiException>().having((e) => e.message, 'message', contains('Ключ'))));
      expect(() => GeminiInvoiceService.parseResponse(429, {}),
          throwsA(isA<GeminiException>().having((e) => e.message, 'message', contains('лимит'))));
      expect(() => GeminiInvoiceService.parseResponse(200, {'candidates': []}),
          throwsA(isA<GeminiException>()));
      expect(
          () => GeminiInvoiceService.parseResponse(200, {
                'candidates': [
                  {'content': {'parts': [{'text': 'не json'}]}}
                ]
              }),
          throwsA(isA<GeminiException>()));
    });
  });
}
