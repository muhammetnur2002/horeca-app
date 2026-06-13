// pdf_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'pdf_saver.dart';

class PdfGenerator {
  static Future<pw.Font> _loadFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      return pw.Font.ttf(fontData.buffer.asByteData());
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  /// Убирает ".0" у целых чисел, оставляя остальные как есть.
  static String _formatQuantity(String? value) {
    if (value == null || value.isEmpty) return '';
    final d = double.tryParse(value);
    if (d == null) return value;          // не число — вернём как есть
    if (d == d.truncateToDouble()) {      // целое (например 1.0, 10.0)
      return d.toInt().toString();
    }
    return value;                         // дробное (например 2.5) — оставим
  }

  // Генерация заявки (таблица)
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
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('$establishmentName', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('$department', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('${DateTime.now().toLocal().toString().split('.')[0]}', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: font),
            headers: ['Товар', 'Количество', 'Ед. изм.'],
            data: items.map((i) => [
              i['name']!,
              _formatQuantity(i['quantity']),  // <-- форматируем количество
              i['unit']!,
            ]).toList(),
          ),
        ],
      ),
    ));
    return pdf.save();
  }

  // Генерация отчёта инвентаризации
  static Future<Uint8List> generateInventoryPdf({
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
    String? responsiblePerson,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

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
            data: items.map((i) => [
              i['name'] ?? '',
              _formatQuantity(i['remaining'] ?? i['quantity']),  // форматируем остаток
              i['unit'] ?? '',
            ]).toList(),
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

  static Future<void> downloadFile(Uint8List bytes, String fileName) async {
    await saveFile(bytes, fileName);
  }
}