/// Заявка строками и сверка с накладной.
///
/// Статусы строки: пришло как заказали, меньше, не привезли, лишнее.
library;

enum ReceiptStatus { matched, short, missing, extra }

class SupplyLine {
  final String productId;
  final String name;
  final double quantity;
  final String unit;

  const SupplyLine({
    this.productId = '',
    required this.name,
    required this.quantity,
    this.unit = 'шт',
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };

  factory SupplyLine.fromJson(Map<String, dynamic> json) => SupplyLine(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'шт',
      );
}

class SupplyRequest {
  final String id;
  final DateTime createdAt;
  final String departmentLabel;
  final List<SupplyLine> lines;

  const SupplyRequest({
    required this.id,
    required this.createdAt,
    required this.departmentLabel,
    required this.lines,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'departmentLabel': departmentLabel,
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory SupplyRequest.fromJson(Map<String, dynamic> json) => SupplyRequest(
        id: json['id'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        departmentLabel: json['departmentLabel'] as String? ?? '',
        lines: [
          for (final raw in (json['lines'] as List? ?? []))
            if (raw is Map) SupplyLine.fromJson(Map<String, dynamic>.from(raw)),
        ],
      );
}

class ReceiptLine {
  final String productId;
  final String name;
  final String unit;
  final double orderedQty;
  final double receivedQty;
  final ReceiptStatus status;

  const ReceiptLine({
    this.productId = '',
    required this.name,
    this.unit = 'шт',
    required this.orderedQty,
    required this.receivedQty,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'unit': unit,
        'orderedQty': orderedQty,
        'receivedQty': receivedQty,
        'status': status.name,
      };

  factory ReceiptLine.fromJson(Map<String, dynamic> json) => ReceiptLine(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? 'шт',
        orderedQty: (json['orderedQty'] as num?)?.toDouble() ?? 0,
        receivedQty: (json['receivedQty'] as num?)?.toDouble() ?? 0,
        status: ReceiptStatus.values.asNameMap()[json['status']] ??
            ReceiptStatus.extra,
      );
}

class GoodsReceipt {
  final String id;
  final String? requestId;
  final DateTime createdAt;
  final String source;
  final List<ReceiptLine> lines;

  const GoodsReceipt({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.lines,
    this.requestId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'createdAt': createdAt.toIso8601String(),
        'source': source,
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory GoodsReceipt.fromJson(Map<String, dynamic> json) => GoodsReceipt(
        id: json['id'] as String? ?? '',
        requestId: json['requestId'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        source: json['source'] as String? ?? 'manual',
        lines: [
          for (final raw in (json['lines'] as List? ?? []))
            if (raw is Map) ReceiptLine.fromJson(Map<String, dynamic>.from(raw)),
        ],
      );
}

/// Имя для сверки: без регистра, «ё» как «е», без лишних знаков.
String normalizeGoodsName(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]+'), ' ')
      .trim();
}

bool sameQty(double ordered, double received) {
  final diff = (ordered - received).abs();
  if (diff <= 0.001) return true;
  if (ordered.abs() < 0.001) return diff <= 0.001;
  return diff / ordered.abs() <= 0.02;
}

String receiptStatusLabel(ReceiptStatus status) {
  switch (status) {
    case ReceiptStatus.matched:
      return 'Пришло как заказали';
    case ReceiptStatus.short:
      return 'Меньше';
    case ReceiptStatus.missing:
      return 'Не привезли';
    case ReceiptStatus.extra:
      return 'Лишнее';
  }
}

/// Сверяет заказанные строки с тем, что приехало.
/// Лишнее не смешивается с заказом: это отдельные строки.
List<ReceiptLine> matchDelivery({
  required List<SupplyLine> ordered,
  required List<SupplyLine> arrived,
}) {
  final used = <int>{};
  final out = <ReceiptLine>[];

  int? findArrived(String name) {
    final key = normalizeGoodsName(name);
    if (key.isEmpty) return null;
    int? loose;
    for (var i = 0; i < arrived.length; i++) {
      if (used.contains(i)) continue;
      final other = normalizeGoodsName(arrived[i].name);
      if (other.isEmpty) continue;
      if (other == key) return i;
      if (loose == null &&
          key.length >= 4 &&
          (other.contains(key) || key.contains(other))) {
        loose = i;
      }
    }
    return loose;
  }

  for (final order in ordered) {
    if (order.name.trim().isEmpty || order.quantity <= 0) continue;
    final index = findArrived(order.name);
    if (index == null) {
      out.add(ReceiptLine(
        productId: order.productId,
        name: order.name,
        unit: order.unit,
        orderedQty: order.quantity,
        receivedQty: 0,
        status: ReceiptStatus.missing,
      ));
      continue;
    }
    used.add(index);
    final got = arrived[index];
    final received = got.quantity < 0 ? 0.0 : got.quantity;
    final ReceiptStatus status;
    if (received <= 0.001) {
      status = ReceiptStatus.missing;
    } else if (sameQty(order.quantity, received)) {
      status = ReceiptStatus.matched;
    } else if (received < order.quantity) {
      status = ReceiptStatus.short;
    } else {
      status = ReceiptStatus.extra;
    }
    out.add(ReceiptLine(
      productId: order.productId,
      name: order.name,
      unit: got.unit.trim().isEmpty ? order.unit : got.unit,
      orderedQty: order.quantity,
      receivedQty: received,
      status: status,
    ));
  }

  for (var i = 0; i < arrived.length; i++) {
    if (used.contains(i)) continue;
    final line = arrived[i];
    if (line.name.trim().isEmpty || line.quantity <= 0) continue;
    out.add(ReceiptLine(
      productId: line.productId,
      name: line.name,
      unit: line.unit,
      orderedQty: 0,
      receivedQty: line.quantity,
      status: ReceiptStatus.extra,
    ));
  }
  return out;
}

/// Вчерашняя заявка, если она есть. Иначе самая свежая.
SupplyRequest? pickRequestToReceive(List<SupplyRequest> requests, DateTime now) {
  if (requests.isEmpty) return null;
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final fromYesterday = requests.where((r) {
    return !r.createdAt.isBefore(yesterday) && r.createdAt.isBefore(today);
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (fromYesterday.isNotEmpty) return fromYesterday.first;
  final sorted = [...requests]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.first;
}

GoodsReceipt? receiptForRequest(List<GoodsReceipt> receipts, String? requestId) {
  if (requestId == null) return null;
  final matched = receipts.where((r) => r.requestId == requestId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (matched.isEmpty) return null;
  return matched.first;
}
