import 'package:horeca_app/features/custom_template/data/template_models.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class FieldMatcher {
  static final Map<TemplateField, List<String>> _synonyms = {
    TemplateField.productName: [
      'наименование', 'название', 'товар', 'продукт', 'позиция',
      'номенклатура', 'name', 'item', 'product', 'title',
    ],
    TemplateField.quantity: [
      'количество', 'кол-во', 'кол во', 'остаток', 'остатки', 'шт-во',
      'qty', 'quantity', 'amount', 'count', 'balance', 'stock',
    ],
    TemplateField.unit: [
      'единица', 'ед.', 'ед изм', 'единица измерения', 'изм',
      'unit', 'measure', 'uom',
    ],
    TemplateField.category: [
      'категория', 'группа', 'тип', 'category', 'group', 'type',
    ],
    TemplateField.department: [
      'отдел', 'подразделение', 'участок', 'department', 'zone',
    ],
  };

  /// Возвращает наиболее вероятное поле и уверенность (0.0 - 1.0)
  static (TemplateField, double) matchField(String header) {
    final normalized = header.toLowerCase().trim()
        .replaceAll(RegExp(r'[.\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    TemplateField bestField = TemplateField.notUsed;
    double bestScore = 0.0;

    for (final entry in _synonyms.entries) {
      for (final synonym in entry.value) {
        final score = _similarity(normalized, synonym);
        if (score > bestScore) {
          bestScore = score;
          bestField = entry.key;
        }
      }
    }

    // Порог уверенности — если совпадение слабое, считаем что не нашли
    if (bestScore < 0.5) {
      return (TemplateField.notUsed, 0.0);
    }
    return (bestField, bestScore);
  }

  /// Простая мера схожести строк: точное совпадение, содержание, или похожесть
  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.contains(b) || b.contains(a)) return 0.85;

    // Подсчёт совпадающих слов
    final wordsA = a.split(' ').where((w) => w.isNotEmpty).toSet();
    final wordsB = b.split(' ').where((w) => w.isNotEmpty).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final common = wordsA.intersection(wordsB).length;
    final total = wordsA.union(wordsB).length;
    return total == 0 ? 0.0 : common / total;
  }

  /// Автоматически сопоставляет список заголовков колонок
  static List<ColumnMapping> autoMatchColumns(List<String> headers) {
    final usedFields = <TemplateField>{};
    final mappings = <ColumnMapping>[];

    for (int i = 0; i < headers.length; i++) {
      final (field, confidence) = matchField(headers[i]);
      // Не даём двум колонкам занять одно и то же поле — выбираем лучшее совпадение
      final finalField = usedFields.contains(field) ? TemplateField.notUsed : field;
      if (finalField != TemplateField.notUsed) usedFields.add(finalField);

      mappings.add(ColumnMapping(
        originalHeader: headers[i],
        columnIndex: i,
        mappedField: finalField,
        confidence: confidence,
      ));
    }
    return mappings;
  }

  /// Опциональное улучшение через AI (требует интернет)
  static Future<List<ColumnMapping>?> tryAiMatch(List<String> headers) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://steep-sun-4c82.nuryagdyyewmuhammetnur.workers.dev/',
        data: {'headers': headers},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          // Dio in your setup expects timeouts as int? (milliseconds), not Duration
          sendTimeout: const Duration(seconds: 10).inMilliseconds,
          receiveTimeout: const Duration(seconds: 10).inMilliseconds,
        ),
      );

      final List<dynamic> results = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      final mappings = <ColumnMapping>[];
      for (int i = 0; i < headers.length; i++) {
        final match = results.firstWhere(
          (r) => r['header'] == headers[i],
          orElse: () => null,
        );
        TemplateField field = TemplateField.notUsed;
        double confidence = 0.0;
        if (match != null) {
          field = TemplateField.values.firstWhere(
            (f) => f.name == match['field'],
            orElse: () => TemplateField.notUsed,
          );
          confidence = (match['confidence'] as num?)?.toDouble() ?? 0.0;
        }
        mappings.add(ColumnMapping(
          originalHeader: headers[i],
          columnIndex: i,
          mappedField: field,
          confidence: confidence,
        ));
      }
      return mappings;
    } catch (e) {
      return null; // нет интернета или ошибка — используем офлайн-словарь
    }
  }
}