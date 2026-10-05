/// Текст отчёта о приёмке поставки: что пришло, что не пришло, недовоз.
library;

import 'package:horeca_app/features/stock/domain/receipt_line.dart';

String _q(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _money(double v) {
  final r = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '−' : '');
  for (var i = 0; i < r.length; i++) {
    if (i > 0 && (r.length - i) % 3 == 0) b.write(' ');
    b.write(r[i]);
  }
  return b.toString();
}

String buildReceiptReport({
  required String venueName,
  required DateTime at,
  required List<ReceiptLine> lines,
  String? requestTitle,
  String? staffName,
  String? note,
  String currency = '',
}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final date =
      '${two(at.day)}.${two(at.month)}.${at.year} ${two(at.hour)}:${two(at.minute)}';

  final full = <ReceiptLine>[];
  final partial = <ReceiptLine>[];
  final missing = <ReceiptLine>[];
  final extra = <ReceiptLine>[];
  for (final l in lines) {
    if (l.ordered == null) {
      if (l.received > 0) extra.add(l);
    } else if (l.received <= 0) {
      missing.add(l);
    } else if (l.received < l.ordered!) {
      partial.add(l);
    } else {
      full.add(l);
    }
  }

  final b = StringBuffer()
    ..writeln('📦 Приёмка поставки — $venueName')
    ..writeln(date);
  if (requestTitle != null) b.writeln('По заявке: $requestTitle');
  if (staffName != null) b.writeln('Принял(а): $staffName');

  void section(
      String title, List<ReceiptLine> list, String Function(ReceiptLine) row) {
    if (list.isEmpty) return;
    b
      ..writeln()
      ..writeln(title);
    for (final l in list) {
      b.writeln('• ${l.productName} — ${row(l)}');
    }
  }

  section('✅ Пришло полностью:', full, (l) {
    final over = l.received - l.ordered!;
    return '${_q(l.received)} ${l.unit}'
        '${over > 0 ? ' (больше заявки на ${_q(over)})' : ''}';
  });
  section(
      '⚠️ Пришло не всё:',
      partial,
      (l) => '${_q(l.received)} из ${_q(l.ordered!)} ${l.unit}, '
          'недовоз ${_q(l.ordered! - l.received)}');
  section('❌ Не пришло:', missing, (l) => '${_q(l.ordered!)} ${l.unit}');
  section('➕ Сверх заявки:', extra, (l) => '${_q(l.received)} ${l.unit}');

  // Сумма — если по строкам есть цены (из накладной/чека или вручную).
  final priced = lines.where((l) => l.sum != null && l.received > 0);
  if (priced.isNotEmpty) {
    final total = priced.fold<double>(0, (a, l) => a + l.sum!);
    b
      ..writeln()
      ..writeln('💰 Сумма по строкам: ${_money(total)}'
          '${currency.isEmpty ? '' : ' $currency'}');
  }
  final unlinked = lines.where((l) => l.productId == null && l.received > 0);
  if (unlinked.isNotEmpty) {
    b.writeln('ℹ️ Без товара в каталоге (не в остатках): '
        '${unlinked.map((l) => l.productName).join(', ')}');
  }

  if (note != null && note.trim().isNotEmpty) {
    b
      ..writeln()
      ..writeln('Комментарий: ${note.trim()}');
  }
  return b.toString().trimRight();
}
