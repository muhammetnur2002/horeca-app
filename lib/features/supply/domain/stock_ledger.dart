/// Остаток = прошлый остаток + приход − расход − списания.
/// Инвентаризация (count) подставляет посчитанный факт вместо расчёта.
library;

enum StockMoveKind { receipt, writeOff, consumption, count }

enum StockMark { high, low, bad, stable }

/// Пороги меток. Их же показывает отчёт.
///
/// Красный — ноль и ниже. Жёлтый — ниже минимума. Зелёный — в 3 раза выше
/// минимума. Без метки — между минимумом и этим порогом, или минимума нет.
class StockThresholds {
  static const double highMultiple = 3;
}

class StockMove {
  final String id;
  final DateTime at;
  final String productKey;
  final String name;
  final String unit;
  final StockMoveKind kind;
  final double qty;

  const StockMove({
    required this.id,
    required this.at,
    required this.productKey,
    required this.name,
    required this.unit,
    required this.kind,
    required this.qty,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'productKey': productKey,
        'name': name,
        'unit': unit,
        'kind': kind.name,
        'qty': qty,
      };

  factory StockMove.fromJson(Map<String, dynamic> json) => StockMove(
        id: json['id'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        productKey: json['productKey'] as String? ?? '',
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? 'шт',
        kind: StockMoveKind.values.asNameMap()[json['kind']] ??
            StockMoveKind.receipt,
        qty: (json['qty'] as num?)?.toDouble() ?? 0,
      );
}

class StockReportRow {
  final String productKey;
  final String name;
  final String unit;
  final double opening;
  final double incoming;
  final double consumption;
  final double writeOff;
  final double closing;
  final bool countedInPeriod;
  final StockMark mark;

  const StockReportRow({
    required this.productKey,
    required this.name,
    required this.unit,
    required this.opening,
    required this.incoming,
    required this.consumption,
    required this.writeOff,
    required this.closing,
    required this.countedInPeriod,
    required this.mark,
  });
}

String nameProductKey(String name) {
  final normalized = name
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]+'), ' ')
      .trim();
  return 'name:$normalized';
}

StockMark markStock({required double balance, double? minimum}) {
  if (balance <= 0) return StockMark.bad;
  if (minimum == null || minimum <= 0) return StockMark.stable;
  if (balance < minimum) return StockMark.low;
  if (balance >= minimum * StockThresholds.highMultiple) return StockMark.high;
  return StockMark.stable;
}

String stockMarkLabel(StockMark mark) {
  switch (mark) {
    case StockMark.high:
      return 'Много';
    case StockMark.low:
      return 'Мало';
    case StockMark.bad:
      return 'Плохо';
    case StockMark.stable:
      return 'Норма';
  }
}

double balanceAt(List<StockMove> moves, DateTime at) {
  final relevant = moves.where((m) => !m.at.isAfter(at)).toList()
    ..sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
  var balance = 0.0;
  for (final move in relevant) {
    switch (move.kind) {
      case StockMoveKind.count:
        balance = move.qty;
      case StockMoveKind.receipt:
        balance += move.qty;
      case StockMoveKind.writeOff:
      case StockMoveKind.consumption:
        balance -= move.qty;
    }
  }
  return balance;
}

List<StockReportRow> buildStockReport({
  required List<StockMove> moves,
  required DateTime from,
  required DateTime to,
  Map<String, double> minimums = const {},
}) {
  final keys = <String>{};
  for (final move in moves) {
    if (move.productKey.isEmpty) continue;
    keys.add(move.productKey);
  }
  final rows = <StockReportRow>[];
  for (final key in keys) {
    final own = moves.where((m) => m.productKey == key).toList();
    if (own.isEmpty) continue;
    final before = own.where((m) => m.at.isBefore(from)).toList();
    final inside = own.where((m) => !m.at.isBefore(from) && !m.at.isAfter(to)).toList();
    if (before.isEmpty && inside.isEmpty) continue;
    final latest = (inside.isNotEmpty ? inside : before)
      ..sort((a, b) => a.at.compareTo(b.at));
    final name = latest.last.name;
    final unit = latest.last.unit;
    double sum(StockMoveKind kind) => inside
        .where((m) => m.kind == kind)
        .fold(0.0, (total, m) => total + m.qty);
    rows.add(StockReportRow(
      productKey: key,
      name: name,
      unit: unit,
      opening: balanceAt(before, from),
      incoming: sum(StockMoveKind.receipt),
      consumption: sum(StockMoveKind.consumption),
      writeOff: sum(StockMoveKind.writeOff),
      closing: balanceAt(own, to),
      countedInPeriod: inside.any((m) => m.kind == StockMoveKind.count),
      mark: markStock(balance: balanceAt(own, to), minimum: minimums[key]),
    ));
  }
  rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return rows;
}
