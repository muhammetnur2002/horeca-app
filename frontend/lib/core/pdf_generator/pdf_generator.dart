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
      return pw.Font.helvetica();
    }
  }

  static String _formatQuantity(String? value) {
    if (value == null || value.isEmpty) return '';
    final d = double.tryParse(value);
    if (d == null) return value;
    if (d == d.truncateToDouble()) return d.toInt().toString();
    return value;
  }

  // ---------- Заявка ----------
  static Future<Uint8List> generateRequestPdf({
    required String title,
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    final rows = items
        .map((i) => [
              i['name'] ?? '',
              _formatQuantity(i['quantity']),
              i['unit'] ?? '',
            ])
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(title,
              style: pw.TextStyle(
                  font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(establishmentName, style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text(department, style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text(
              DateTime.now().toLocal().toString().split('.')[0],
              style: pw.TextStyle(font: font, fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                children: ['Товар', 'Количество', 'Ед. изм.']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  font: font,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12)),
                        ))
                    .toList(),
              ),
              ...rows.map((row) => pw.TableRow(
                    children: row
                        .map((cell) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(cell,
                                  style: pw.TextStyle(font: font, fontSize: 11)),
                            ))
                        .toList(),
                  )),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  // ---------- Отчёт инвентаризации ----------
  static Future<Uint8List> generateInventoryPdf({
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
    String? responsiblePerson,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    final rows = items
        .map((i) => [
              i['name'] ?? '',
              _formatQuantity(i['remaining'] ?? i['quantity']),
              (i['unit'] != null && i['unit']!.isNotEmpty) ? i['unit']! : 'шт',
            ])
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('Отчёт об инвентаризации',
              style: pw.TextStyle(
                  font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(establishmentName, style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text(department, style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text(
              DateTime.now().toLocal().toString().split('.')[0],
              style: pw.TextStyle(font: font, fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                children: ['Товар', 'Остаток', 'Ед. изм.']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  font: font,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12)),
                        ))
                    .toList(),
              ),
              ...rows.map((row) => pw.TableRow(
                    children: row
                        .map((cell) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(cell,
                                  style: pw.TextStyle(font: font, fontSize: 11)),
                            ))
                        .toList(),
                  )),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Ответственный: ${(responsiblePerson != null && responsiblePerson.isNotEmpty) ? responsiblePerson : "_______________"}',
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<void> downloadFile(Uint8List bytes, String fileName) async {
    await saveFile(bytes, fileName);
  }
}