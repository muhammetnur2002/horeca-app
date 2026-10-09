import 'dart:convert';

import 'package:horeca_app/features/supply/domain/supply_models.dart';

/// Достаёт таблицу товаров из ответа модели.
/// Модель просят вернуть JSON, но вокруг часто бывают пояснения и ```.
List<SupplyLine> parseInvoiceTable(String raw) {
  final start = raw.indexOf('[');
  final end = raw.lastIndexOf(']');
  if (start < 0 || end <= start) {
    throw const FormatException('В ответе нет таблицы');
  }
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('В ответе нет таблицы');
  }
  final lines = <SupplyLine>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final name = (item['name'] ?? item['товар'] ?? '').toString().trim();
    final qtyRaw = item['qty'] ?? item['quantity'] ?? item['количество'];
    final qty = qtyRaw is num ? qtyRaw.toDouble() : double.tryParse('$qtyRaw');
    if (name.isEmpty || qty == null || qty <= 0) continue;
    final unit = (item['unit'] ?? item['ед'] ?? 'шт').toString().trim();
    lines.add(SupplyLine(
      name: name,
      quantity: qty,
      unit: unit.isEmpty ? 'шт' : unit,
    ));
  }
  if (lines.isEmpty) {
    throw const FormatException('Таблица пустая');
  }
  return lines;
}
