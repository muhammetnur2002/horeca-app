/// Расчёт товарного учёта по журналу движений.
///
/// Формула: остаток = начало + приход − списания − продажи ± корректировки.
/// Инвентаризация ('count') и стартовые остатки ('baseline') — это не
/// изменение, а замер: их количество — фактический остаток на момент
/// подсчёта. Разница между расчётным остатком перед замером и замером —
/// это расход, который не прошёл через приложение (продажи, порции, потери).
/// Когда подключится iiko, сюда добавятся продажи ('sale'), и разница
/// станет «недостачей» сверх продаж.
library;

/// Виды движений (совпадают со значениями StockMovements.kind).
abstract final class MovementKind {
  static const baseline = 'baseline';
  static const receipt = 'receipt';
  static const sale = 'sale';
  static const writeoff = 'writeoff';
  static const count = 'count';
  static const adjustment = 'adjustment';

  /// Замеры: количество — абсолютный остаток, а не изменение.
  static bool isAbsolute(String kind) => kind == baseline || kind == count;
}

/// Минимум данных о движении для расчёта.
class Movement {
  final String productId;
  final String kind;

  /// Для замеров — фактический остаток; для остальных — изменение со
  /// знаком (приход +, списание и продажа −).
  final double quantity;
  final DateTime occurredAt;

  const Movement({
    required this.productId,
    required this.kind,
    required this.quantity,
    required this.occurredAt,
  });
}

/// Итог по товару за период.
class LedgerLine {
  final String productId;

  /// Остаток на начало периода; null — замеров до начала не было.
  final double? start;
  final double received;

  /// Списано (положительное число).
  final double writtenOff;

  /// Продано по данным кассы (положительное число).
  final double sold;
  final double adjusted;

  /// Расход, выявленный инвентаризациями за период: сколько ушло сверх
  /// учтённого (положительное — ушло больше, отрицательное — нашлось).
  final double consumption;

  /// Остаток на конец периода; null — ни одного замера ещё не было.
  final double? end;

  /// Дата последнего замера (инвентаризации/стартовых остатков).
  final DateTime? lastCountAt;

  const LedgerLine({
    required this.productId,
    required this.start,
    required this.received,
    required this.writtenOff,
    required this.sold,
    required this.adjusted,
    required this.consumption,
    required this.end,
    required this.lastCountAt,
  });

  bool get hasActivity =>
      received != 0 ||
      writtenOff != 0 ||
      sold != 0 ||
      adjusted != 0 ||
      consumption != 0;
}

class StockLedger {
  /// Считает итоги по каждому товару за период [from, to).
  /// [movements] могут идти в любом порядке и включать движения до [from]
  /// (они нужны для остатка на начало).
  static Map<String, LedgerLine> compute(
    Iterable<Movement> movements, {
    required DateTime from,
    required DateTime to,
  }) {
    final byProduct = <String, List<Movement>>{};
    for (final m in movements) {
      if (!m.occurredAt.isBefore(to)) continue;
      byProduct.putIfAbsent(m.productId, () => []).add(m);
    }

    final result = <String, LedgerLine>{};
    for (final entry in byProduct.entries) {
      final list = entry.value
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

      double? balance;
      double? start;
      var startTaken = false;
      var received = 0.0, writtenOff = 0.0, sold = 0.0, adjusted = 0.0;
      var consumption = 0.0;
      DateTime? lastCountAt;
      var known = false;

      for (final m in list) {
        final inPeriod = !m.occurredAt.isBefore(from);
        if (inPeriod && !startTaken) {
          start = known ? balance : null;
          startTaken = true;
        }

        if (MovementKind.isAbsolute(m.kind)) {
          // Расход считаем только между замерами: до первого замера
          // начальный остаток неизвестен, а стартовые остатки — новая
          // точка отсчёта, а не проверка.
          if (inPeriod && known && m.kind == MovementKind.count) {
            consumption += balance! - m.quantity;
          }
          balance = m.quantity;
          known = true;
          lastCountAt = m.occurredAt;
          continue;
        }

        // До первого замера остаток неизвестен — движения копим от нуля,
        // чтобы приход до стартовой инвентаризации не потерялся в сумме.
        balance = (balance ?? 0) + m.quantity;
        if (!inPeriod) continue;
        switch (m.kind) {
          case MovementKind.receipt:
            received += m.quantity;
          case MovementKind.writeoff:
            writtenOff -= m.quantity;
          case MovementKind.sale:
            sold -= m.quantity;
          default:
            adjusted += m.quantity;
        }
      }
      if (!startTaken) start = known ? balance : null;

      result[entry.key] = LedgerLine(
        productId: entry.key,
        start: start,
        received: received,
        writtenOff: writtenOff,
        sold: sold,
        adjusted: adjusted,
        consumption: _round(consumption),
        end: lastCountAt == null ? null : _round(balance!),
        lastCountAt: lastCountAt,
      );
    }
    return result;
  }

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;
}
