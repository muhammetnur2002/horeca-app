import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

class PdfGenerator {
  static Future<pw.Font> _loadFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      return pw.Font.ttf(fontData.buffer.asByteData());
    } catch (_) {
      return pw.Font.helvetica();
    }
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
            data: items.map((i) => [i['name']!, i['quantity']!, i['unit']!]).toList(),
          ),
        ],
      ),
    ));
    return pdf.save();
  }

  // Генерация отчёта инвентаризации (таблица) – с защитой от отсутствующих ключей
  static Future<Uint8List> generateInventoryPdf({
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
    String? responsiblePerson,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();

    final rows = items.map((i) => [
      i['name'] ?? '',
      i['remaining'] ?? '',
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
          ],
        ],
      ),
    ));
    return pdf.save();
  }

  // Сохранение/отправка файла (только для Android/iOS/десктоп)
  static Future<void> downloadFile(Uint8List bytes, String fileName) async {
    // Если всё-таки понадобится веб — нужно вынести в отдельный файл с условным импортом
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: fileName);
  }
}