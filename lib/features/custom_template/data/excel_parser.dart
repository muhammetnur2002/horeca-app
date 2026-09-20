import 'dart:io';
import 'package:excel/excel.dart';

class ParsedTemplate {
  final List<String> headers;
  final List<List<String>> sampleRows; // первые несколько строк для предпросмотра
  final String sheetName;

  ParsedTemplate({required this.headers, required this.sampleRows, required this.sheetName});
}

class ExcelParser {
  static Future<ParsedTemplate?> parseFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) return null;
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) return null;

      // Первая строка — заголовки
      final headerRow = sheet.rows.first;
      final headers = headerRow.map((cell) => cell?.value?.toString() ?? '').toList();

      // Следующие до 5 строк — пример данных для предпросмотра
      final sampleRows = <List<String>>[];
      for (int i = 1; i < sheet.rows.length && i <= 5; i++) {
        final row = sheet.rows[i];
        sampleRows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
      }

      return ParsedTemplate(headers: headers, sampleRows: sampleRows, sheetName: sheetName);
    } catch (e) {
      return null;
    }
  }
}
