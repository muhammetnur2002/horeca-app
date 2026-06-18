import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_saver.dart';

class PdfGenerator {
  static final _orange  = PdfColor.fromHex('F5862E');
  static final _dark    = PdfColor.fromHex('1A1E2E');
  static final _muted   = PdfColor.fromHex('8B8FA8');
  static final _bgLight = PdfColor.fromHex('F8F9FF');
  static final _green   = PdfColor.fromHex('639922');

  static Future<pw.Font> _loadFont() async {
    try {
      final d = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      return pw.Font.ttf(d.buffer.asByteData());
    } catch (_) { return pw.Font.helvetica(); }
  }

  static Future<pw.Font> _loadBoldFont() async {
    try {
      final d = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      return pw.Font.ttf(d.buffer.asByteData());
    } catch (_) { return pw.Font.helveticaBold(); }
  }

  static String _formatQuantity(String? value) {
    if (value == null || value.isEmpty) return '';
    final d = double.tryParse(value);
    if (d == null) return value;
    if (d == d.truncateToDouble()) return d.toInt().toString();
    return value;
  }

  static String _formattedDate() {
    final now = DateTime.now();
    const months = ['','января','февраля','марта','апреля','мая','июня',
        'июля','августа','сентября','октября','ноября','декабря'];
    final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    return '${now.day} ${months[now.month]} ${now.year}, $time';
  }

  static pw.Widget _buildHeader({
    required pw.Font font, required pw.Font boldFont,
    required String title, required String establishmentName, required String subtitle,
  }) {
    return pw.Column(children: [
      pw.Container(color: _dark,
        padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Akyl', style: pw.TextStyle(font: boldFont, fontSize: 22, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('управляй с умом', style: pw.TextStyle(font: font, fontSize: 10, color: _muted)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(establishmentName, style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text(_formattedDate(), style: pw.TextStyle(font: font, fontSize: 10, color: _muted)),
            ]),
          ],
        )),
      pw.Container(color: _orange,
        padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(title.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 11,
              color: PdfColors.white, letterSpacing: 1.2)),
          pw.Text(subtitle, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white)),
        ])),
    ]);
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(color: _dark,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Akyl — управляй с умом',
            style: pw.TextStyle(font: font, fontSize: 9, color: _muted)),
        pw.Text(_formattedDate(),
            style: pw.TextStyle(font: font, fontSize: 9, color: _muted)),
      ]));
  }

  static pw.Widget _sectionTitle(String title, pw.Font boldFont, PdfColor color) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 10,
          color: color, letterSpacing: 0.8)),
      pw.SizedBox(height: 3),
      pw.Divider(color: color, thickness: 1),
    ]);
  }

  static pw.Widget _buildTable({
    required pw.Font font, required pw.Font boldFont,
    required List<String> headers, required List<List<String>> rows,
    PdfColor? accentColor,
  }) {
    final accent = accentColor ?? _orange;
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: accent),
      cellStyle: pw.TextStyle(font: font, fontSize: 10, color: _dark),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F8F9FF')),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
      },
      border: pw.TableBorder.all(color: PdfColor.fromHex('E0E0E0'), width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }

  static pw.Widget _infoCards({
    required pw.Font font, required pw.Font boldFont,
    required String label1, required String value1,
    required String label2, required String value2,
    required PdfColor valueColor,
  }) {
    pw.Widget card(String lbl, String val, PdfColor col) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(color: _bgLight,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromHex('E0E0E0'), width: 0.5)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(lbl, style: pw.TextStyle(font: boldFont, fontSize: 9,
              color: _muted, letterSpacing: 0.5)),
          pw.SizedBox(height: 4),
          pw.Text(val, style: pw.TextStyle(font: boldFont, fontSize: 14, color: col)),
        ])));
    return pw.Row(children: [
      card(label1, value1, valueColor),
      pw.SizedBox(width: 12),
      card(label2, value2, _dark),
    ]);
  }

  // ── PDF Заявка ────────────────────────────────────────────────────────────
  static Future<Uint8List> generateRequestPdf({
    required String title,
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
  }) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: boldFont));

    final rows = items.map((i) => [
      i['name'] ?? '',
      _formatQuantity(i['quantity']),
      i['unit'] ?? '',
    ]).toList();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 100,
      margin: const pw.EdgeInsets.all(0),
      header: (ctx) => _buildHeader(
        font: font, boldFont: boldFont,
        title: 'Заявка на товары',
        establishmentName: establishmentName,
        subtitle: department),
      footer: (ctx) => _buildFooter(font),
      build: (ctx) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 8),
          child: _infoCards(
            font: font, boldFont: boldFont,
            label1: 'ОТДЕЛ', value1: department,
            label2: 'ПОЗИЦИЙ', value2: '${items.length} шт',
            valueColor: _orange)),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: _sectionTitle('Список товаров', boldFont, _orange)),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: _buildTable(
            font: font, boldFont: boldFont,
            headers: ['Наименование', 'Количество', 'Ед. изм.'],
            rows: rows)),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Divider(color: _muted, thickness: 0.5),
            pw.SizedBox(height: 12),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Заведение: $establishmentName',
                  style: pw.TextStyle(font: font, fontSize: 11, color: _dark)),
              pw.Text('Подпись: ___________________',
                  style: pw.TextStyle(font: font, fontSize: 11, color: _dark)),
            ]),
            pw.SizedBox(height: 4),
            pw.Text('Сформировано: ${_formattedDate()}',
                style: pw.TextStyle(font: font, fontSize: 9, color: _muted)),
          ])),
      ],
    ));
    return pdf.save();
  }

  // ── PDF Инвентаризация ────────────────────────────────────────────────────
  static Future<Uint8List> generateInventoryPdf({
    required String establishmentName,
    required String department,
    required List<Map<String, String>> items,
    String? responsiblePerson,
  }) async {
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: boldFont));

    final rows = items.map((i) => [
      i['name'] ?? '',
      _formatQuantity(i['remaining'] ?? i['quantity']),
      (i['unit'] != null && i['unit']!.isNotEmpty) ? i['unit']! : 'шт',
    ]).toList();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 100,
      margin: const pw.EdgeInsets.all(0),
      header: (ctx) => _buildHeader(
        font: font, boldFont: boldFont,
        title: 'Инвентаризация',
        establishmentName: establishmentName,
        subtitle: department),
      footer: (ctx) => _buildFooter(font),
      build: (ctx) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 8),
          child: _infoCards(
            font: font, boldFont: boldFont,
            label1: 'ОТДЕЛ', value1: department,
            label2: 'ПОЗИЦИЙ', value2: '${items.length} шт',
            valueColor: _green)),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 8),
          child: _sectionTitle('Остатки товаров', boldFont, _green)),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: _buildTable(
            font: font, boldFont: boldFont,
            headers: ['Наименование', 'Остаток', 'Ед. изм.'],
            rows: rows, accentColor: _green)),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Divider(color: _muted, thickness: 0.5),
            pw.SizedBox(height: 12),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(
                'Ответственный: ${(responsiblePerson != null && responsiblePerson.isNotEmpty) ? responsiblePerson : "___________________"}',
                style: pw.TextStyle(font: font, fontSize: 11, color: _dark)),
              pw.Text('Подпись: ___________________',
                  style: pw.TextStyle(font: font, fontSize: 11, color: _dark)),
            ]),
            pw.SizedBox(height: 4),
            pw.Text('Сформировано: ${_formattedDate()}',
                style: pw.TextStyle(font: font, fontSize: 9, color: _muted)),
          ])),
      ],
    ));
    return pdf.save();
  }

  static Future<void> downloadFile(Uint8List bytes, String fileName) async {
    await saveFile(bytes, fileName);
  }
}
