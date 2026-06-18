import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:horeca_app/features/shift_close/presentation/shift_close_screen.dart';

class ShiftClosePdf {
  static Future<void> generateAndShare({
    required BuildContext context,
    required String staffName,
    required List<DessertItem> desserts,
    required double qr,
    required double card,
    required double cash,
    required double totalRevenue,
    required double morningCash,
    required double eveningCash,
    required double inkass,
    required double tomorrowCash,
    required DateTime date,
required String currency,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final fontBold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontBold);
    final theme = pw.ThemeData.withFont(base: ttf, bold: ttfBold);
    final pdf = pw.Document(theme: theme);

    final orange  = PdfColor.fromHex('F5862E');
    final green   = PdfColor.fromHex('639922');
    final dark    = PdfColor.fromHex('1A1E2E');
    final muted   = PdfColor.fromHex('8B8FA8');
    final bgLight = PdfColor.fromHex('F8F9FF');
    final white   = PdfColors.white;
    final red     = PdfColor.fromHex('C0392B');

    const months = ['','января','февраля','марта','апреля','мая','июня',
        'июля','августа','сентября','октября','ноября','декабря'];
    final dateStr = '${date.day} ${months[date.month]} ${date.year}';
    final timeStr = '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';

    String fmt(double v) {
      if (v == 0) return '0';
      return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    }

    final writeOffs = desserts.where((d) => d.writeOff > 0).toList();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 100,
      margin: const pw.EdgeInsets.all(0),
      header: (ctx) => pw.Column(children: [
        pw.Container(
          color: dark,
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Akyl', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: white)),
                pw.SizedBox(height: 4),
                pw.Text('управляй с умом', style: pw.TextStyle(fontSize: 10, color: muted)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Отчёт о закрытии смены', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: white)),
                pw.SizedBox(height: 4),
                pw.Text('$dateStr, $timeStr', style: pw.TextStyle(fontSize: 10, color: muted)),
                pw.SizedBox(height: 2),
                pw.Text('Смена: $staffName', style: pw.TextStyle(fontSize: 10, color: muted)),
              ]),
            ],
          ),
        ),
        pw.Container(
          color: orange,
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('ОТЧЁТ О ЗАКРЫТИИ СМЕНЫ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: white, letterSpacing: 1.2)),
            pw.Text(dateStr, style: pw.TextStyle(fontSize: 10, color: white)),
          ]),
        ),
      ]),
      footer: (ctx) => pw.Container(
        color: dark,
        padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Akyl — управляй с умом', style: pw.TextStyle(fontSize: 9, color: muted)),
          pw.Text('Стр. ${ctx.pageNumber}', style: pw.TextStyle(fontSize: 9, color: muted)),
        ]),
      ),
      build: (ctx) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 8),
          child: pw.Row(children: [
            pw.Expanded(child: _pdfBox(label: 'ИТОГОВАЯ ВЫРУЧКА', value: '${fmt(totalRevenue)} $currency', sub: dateStr, valueColor: orange, bg: bgLight)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _pdfBox(label: 'КАССА НА ЗАВТРА', value: '${fmt(tomorrowCash)} $currency', sub: 'наличных в кассе', valueColor: dark, bg: bgLight)),
          ]),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 4),
          child: _pdfSectionTitle('Способы оплаты', orange),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: _pdfTable(
            headers: ['Способ оплаты', 'Сумма'],
            rows: [
              ['QR-код', '${fmt(qr)} $currency'],
              ['Банковская карта', '${fmt(card)} $currency'],
              ['Наличные', '${fmt(cash)} $currency'],
            ],
            totals: ['ИТОГО', '${fmt(totalRevenue)} $currency'],
            accentColor: orange, dark: dark, muted: muted),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 4),
          child: _pdfSectionTitle('Касса', orange),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: _pdfTable(
            headers: ['Позиция', 'Сумма'],
            rows: [
              ['Наличные утром', '${fmt(morningCash)} $currency'],
              ['Наличные вечером', '${fmt(eveningCash)} $currency'],
              if (inkass > 0) ['Инкассация', '${fmt(inkass)} $currency'],
              ['Касса на завтра', '${fmt(tomorrowCash)} $currency'],
            ],
            accentColor: orange, dark: dark, muted: muted),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 4),
          child: _pdfSectionTitle('Остатки десертов', orange),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: _pdfTable(
            headers: ['Наименование', 'Витрина', 'Склад'],
            rows: desserts.map((d) => [d.name, '${d.showcase} шт', '${d.stock} шт']).toList(),
            accentColor: orange, dark: dark, muted: muted),
        ),
        if (writeOffs.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 4),
            child: _pdfSectionTitle('Списания / порча', red),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: _pdfTable(
              headers: ['Наименование', 'Тип', 'Кол-во'],
              rows: writeOffs.map((d) => [
                d.name,
                d.writeOffType == WriteOffType.spoilage ? 'Порча' : 'Списание',
                '${d.writeOff} шт',
              ]).toList(),
              accentColor: red, dark: dark, muted: muted),
          ),
        ],
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Divider(color: muted, thickness: 0.5),
            pw.SizedBox(height: 12),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Сотрудник: $staffName', style: pw.TextStyle(fontSize: 11, color: dark)),
              pw.Text('Подпись: ___________________', style: pw.TextStyle(fontSize: 11, color: dark)),
            ]),
            pw.SizedBox(height: 4),
            pw.Text('Сформировано: $dateStr, $timeStr', style: pw.TextStyle(fontSize: 9, color: muted)),
          ]),
        ),
      ],
    ));

    final Uint8List bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final fileName = 'smena_${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Отчёт о закрытии смены — $dateStr',
    );
  }

  static pw.Widget _pdfBox({
    required String label, required String value,
    required String sub, required PdfColor valueColor, required PdfColor bg,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('E0E0E0'), width: 0.5)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('8B8FA8'), letterSpacing: 0.5)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: valueColor)),
        pw.SizedBox(height: 2),
        pw.Text(sub, style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('8B8FA8'))),
      ]),
    );
  }

  static pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 0.8)),
      pw.SizedBox(height: 3),
      pw.Divider(color: color, thickness: 1),
    ]);
  }

  static pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? totals,
    required PdfColor accentColor,
    required PdfColor dark,
    required PdfColor muted,
  }) {
    final colCount = headers.length;
    final Map<int, pw.TableColumnWidth> widths = {};
    for (int i = 0; i < colCount; i++) {
      widths[i] = i == 0 ? const pw.FlexColumnWidth(3) : const pw.FlexColumnWidth(1.5);
    }
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: accentColor),
      cellStyle: pw.TextStyle(fontSize: 10, color: dark),
      oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F8F9FF')),
      columnWidths: widths,
      border: pw.TableBorder.all(color: PdfColor.fromHex('E0E0E0'), width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }
}