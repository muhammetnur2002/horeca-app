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

  /// Часть движений записана в несовместимой единице и в остаток не вошла.
  final bool mixedUnits;

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
    this.mixedUnits = false,
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

/// Базовая единица и множитель к ней: 500 г = 0,5 кг, 250 мл = 0,25 л.
/// Неизвестная единица остаётся сама собой, без пересчёта.
(String, double) baseUnit(String unit) {
  final u = unit.trim().toLowerCase().replaceAll('.', '');
  switch (u) {
    case 'г':
    case 'гр':
    case 'грамм':
      return ('кг', 0.001);
    case 'кг':
      return ('кг', 1);
    case 'мл':
      return ('л', 0.001);
    case 'л':
    case 'литр':
      return ('л', 1);
    case '':
    case 'шт':
    case 'штук':
      return ('шт', 1);
  }
  return (u, 1);
}

List<StockMove> _ordered(Iterable<StockMove> moves) => moves.toList()
  ..sort((a, b) {
    final byTime = a.at.compareTo(b.at);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  });

/// Единица, в которой считается остаток товара: последнего пересчёта,
/// иначе последнего движения.
String ledgerUnit(Iterable<StockMove> moves) {
  final ordered = _ordered(moves);
  if (ordered.isEmpty) return 'шт';
  for (final move in ordered.reversed) {
    if (move.kind == StockMoveKind.count) return move.unit;
  }
  return ordered.last.unit;
}

/// true — среди движений есть единица, которую нельзя пересчитать
/// в единицу остатка (шт против кг). Такие движения в остаток не идут.
bool hasMixedUnits(Iterable<StockMove> moves, {String? unit}) {
  final target = baseUnit(unit ?? ledgerUnit(moves)).$1;
  return moves.any((m) => baseUnit(m.unit).$1 != target);
}

/// Остаток в единице [unit] (по умолчанию [ledgerUnit]). Граммы и
/// миллилитры пересчитываются в кг и л. Движение в несовместимой единице
/// пропускается: сложить 3 шт и 2 кг нельзя.
double balanceAt(List<StockMove> moves, DateTime at, {String? unit}) {
  final relevant = _ordered(moves.where((m) => !m.at.isAfter(at)));
  final (target, targetFactor) = baseUnit(unit ?? ledgerUnit(moves));
  var balance = 0.0;
  for (final move in relevant) {
    final (base, factor) = baseUnit(move.unit);
    if (base != target) continue;
    final qty = move.qty * factor;
    switch (move.kind) {
      case StockMoveKind.count:
        balance = qty;
      case StockMoveKind.receipt:
        balance += qty;
      case StockMoveKind.writeOff:
      case StockMoveKind.consumption:
        balance -= qty;
    }
  }
  return balance / targetFactor;
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
    final unit = ledgerUnit(own);
    final (target, targetFactor) = baseUnit(unit);
    double sum(StockMoveKind kind) => inside
        .where((m) => m.kind == kind)
        .fold(0.0, (total, m) {
          final (base, factor) = baseUnit(m.unit);
          return base == target ? total + m.qty * factor / targetFactor : total;
        });
    final closing = balanceAt(own, to, unit: unit);
    rows.add(StockReportRow(
      productKey: key,
      name: name,
      unit: unit,
      opening: balanceAt(before, from, unit: unit),
      incoming: sum(StockMoveKind.receipt),
      consumption: sum(StockMoveKind.consumption),
      writeOff: sum(StockMoveKind.writeOff),
      closing: closing,
      countedInPeriod: inside.any((m) => m.kind == StockMoveKind.count),
      mark: markStock(balance: closing, minimum: minimums[key]),
      mixedUnits: hasMixedUnits(own, unit: unit),
    ));
  }
  rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return rows;
}
