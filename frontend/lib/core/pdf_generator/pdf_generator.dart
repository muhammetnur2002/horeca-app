import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_saver.dart';

class PdfGenerator {
  static Future<pw.Font> _loadFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      return pw.Font.ttf(fontData.buffer.asByteData());
    } catch (_) {
      // Если шрифт не загрузился (например, битый файл или отсутствует) – используем встроенный
      return pw.Font.helvetica();
    }
  }

  /// Превращает строку с числом в целое, если нет дробной части.
  static String _formatQuantity(String? value) {
    if (value == null || value.isEmpty) return '';
    final d = double.tryParse(value);
    if (d == null) return value;
    if (d == d.truncateToDouble()) {
      return d.toInt().toString();
    }
    return value;
  }

  // ========== Генерация заявки ==========
  static Future<Uint8List> generateRequestPdf({
    required String title,
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('$establishmentName', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('$department', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('${DateTime.now().toLocal().toString().split('.')[0]}',
              style: pw.TextStyle(font: font, fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: font),
            headers: ['Товар', 'Количество', 'Ед. изм.'],
            data: items.map((i) => [
                  i['name']!,
                  _formatQuantity(i['quantity']),
                  i['unit']!,
                ]).toList(),
          ),
        ],
      ),
    ));
    return pdf.save();
  }

  // ========== Генерация отчёта инвентаризации ==========
  static Future<Uint8List> generateInventoryPdf({
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
    String? responsiblePerson,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    // Формируем строки таблицы с защитой от null
    final rows = items.map((i) => [
          i['name'] ?? '',
          _formatQuantity(i['remaining'] ?? i['quantity']),
          i['unit'] ?? '',
        ]).toList();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Отчёт об инвентаризации',
              style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('$establishmentName', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('$department', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('${DateTime.now().toLocal().toString().split('.')[0]}',
              style: pw.TextStyle(font: font, fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: font),
            headers: ['Товар', 'Остаток', 'Ед. изм.'],
            data: rows,
          ),
          if (responsiblePerson != null && responsiblePerson.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Ответственный: $responsiblePerson', style: pw.TextStyle(font: font)),
          ] else ...[
            pw.SizedBox(height: 20),
            pw.Text('Ответственный: _______________', style: pw.TextStyle(font: font)),
          ],
        ],
      ),
    ));
    return pdf.save();
  }

  /// Скачать/поделиться файлом – автоматически для всех платформ
  static Future<void> downloadFile(Uint8List bytes, String fileName) async {
    await saveFile(bytes, fileName);
  }
}