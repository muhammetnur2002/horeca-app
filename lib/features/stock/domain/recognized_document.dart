/// Результат распознавания накладной или чека: шапка документа и строки.
library;

class RecognizedItem {
  final String name;
  final double quantity;
  final String? unit;

  /// Цена за единицу.
  final double? price;

  /// Сумма строки (если цена за единицу не указана, её считаем из суммы).
  final double? sum;

  const RecognizedItem({
    required this.name,
    required this.quantity,
    this.unit,
    this.price,
    this.sum,
  });

  /// Цена за единицу: напрямую или из суммы строки.
  double? get unitPrice {
    if (price != null && price! > 0) return price;
    if (sum != null && sum! > 0 && quantity > 0) return sum! / quantity;
    return null;
  }
}

class RecognizedDocument {
  /// 'накладная', 'чек' или 'другое'.
  final String kind;
  final String? supplier;
  final String? number;
  final String? date;
  final double? total;
  final List<RecognizedItem> items;

  const RecognizedDocument({
    required this.kind,
    required this.items,
    this.supplier,
    this.number,
    this.date,
    this.total,
  });

  /// Разбор JSON, который возвращает модель. Терпим к пропускам, числам
  /// строкой и запятой вместо точки; строки без названия или количества
  /// отбрасываем.
  factory RecognizedDocument.fromJson(Map<String, dynamic> j) {
    double? num_(Object? v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
      return double.tryParse(s);
    }

    String? str(Object? v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty ? null : s;
    }

    final items = <RecognizedItem>[];
    for (final raw in (j['items'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final name = str(raw['name']);
      final qty = num_(raw['quantity']);
      if (name == null || qty == null || qty <= 0) continue;
      items.add(RecognizedItem(
        name: name,
        quantity: qty,
        unit: str(raw['unit']),
        price: num_(raw['price']),
        sum: num_(raw['sum']),
      ));
    }
    return RecognizedDocument(
      kind: str(j['kind']) ?? 'другое',
      supplier: str(j['supplier']),
      number: str(j['number']),
      date: str(j['date']),
      total: num_(j['total']),
      items: items,
    );
  }
}
