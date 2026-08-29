import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

class ParsedTemplate {
  final List<String> headers;
  final List<List<String>> sampleRows; // первые несколько строк для предпросмотра
  final String sheetName;

  ParsedTemplate({
    required this.headers,
    required this.sampleRows,
    required this.sheetName,
  });
}

/// Разбор выполняется в отдельном изоляте: Excel.decodeBytes на большом файле
/// блокировал UI-поток на несколько секунд.
Map<String, dynamic>? _decodeExcel(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return null;

  final sheetName = excel.tables.keys.first;
  final sheet = excel.tables[sheetName];
  if (sheet == null || sheet.rows.isEmpty) return null;

  final headers = sheet.rows.first
      .map((cell) => cell?.value?.toString() ?? '')
      .toList(growable: false);

  final sampleRows = <List<String>>[];
  for (var i = 1; i < sheet.rows.length && i <= 5; i++) {
    sampleRows.add(sheet.rows[i]
        .map((cell) => cell?.value?.toString() ?? '')
        .toList(growable: false));
  }

  return <String, dynamic>{
    'sheetName': sheetName,
    'headers': headers,
    'sampleRows': sampleRows,
  };
}

class ExcelParser {
  const ExcelParser._();

  /// Максимальный размер файла — защита от попытки разобрать что-то огромное.
  static const maxFileBytes = 20 * 1024 * 1024;

  static Future<ParsedTemplate?> parseBytes(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxFileBytes) return null;
    try {
      final raw = await compute(_decodeExcel, bytes);
      if (raw == null) return null;
      return ParsedTemplate(
        sheetName: raw['sheetName'] as String,
        headers: (raw['headers'] as List).cast<String>(),
        sampleRows: (raw['sampleRows'] as List)
            .map((r) => (r as List).cast<String>())
            .toList(),
      );
    } catch (e, st) {
      debugPrint('ExcelParser: не удалось разобрать файл: $e\n$st');
      return null;
    }
  }
}
