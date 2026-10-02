import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/stock/domain/stock_ledger.dart';

Movement m(String kind, double q, int day, [String p = 'milk']) => Movement(
    productId: p, kind: kind, quantity: q, occurredAt: DateTime(2026, 10, day));

void main() {
  test('начало + приход − списания − конец = расход', () {
    final lines = StockLedger.compute([
      m(MovementKind.baseline, 10, 1),
      m(MovementKind.receipt, 20, 3),
      m(MovementKind.writeoff, -2, 4),
      m(MovementKind.count, 12, 6),
    ], from: DateTime(2026, 10, 2), to: DateTime(2026, 10, 7));
    final l = lines['milk']!;
    expect(l.start, 10);
    expect(l.received, 20);
    expect(l.writtenOff, 2);
    expect(l.consumption, 16); // 10 + 20 − 2 − 12
    expect(l.end, 12);
    expect(l.lastCountAt, DateTime(2026, 10, 6));
  });

  test('несколько инвентаризаций за период суммируют расход', () {
    final l = StockLedger.compute([
      m(MovementKind.baseline, 10, 1),
      m(MovementKind.count, 7, 3), // ушло 3
      m(MovementKind.receipt, 5, 4),
      m(MovementKind.count, 8, 5), // 7 + 5 − 8 = 4
    ], from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 9))['milk']!;
    expect(l.start, isNull); // замеров до начала периода не было
    expect(l.consumption, 7);
    expect(l.end, 8);
  });

  test('после последнего замера остаток считается по движениям', () {
    final l = StockLedger.compute([
      m(MovementKind.count, 4, 1),
      m(MovementKind.receipt, 6, 2),
      m(MovementKind.writeoff, -1, 3),
    ], from: DateTime(2026, 10, 2), to: DateTime(2026, 10, 9))['milk']!;
    expect(l.start, 4);
    expect(l.end, 9);
    expect(l.consumption, 0);
  });

  test('без замеров конечный остаток неизвестен, но приход виден', () {
    final l = StockLedger.compute([m(MovementKind.receipt, 6, 2)],
        from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 9))['milk']!;
    expect(l.end, isNull);
    expect(l.received, 6);
  });

  test('приход до первого замера не превращается в расход', () {
    final l = StockLedger.compute([
      m(MovementKind.receipt, 6, 2),
      m(MovementKind.count, 4, 3),
      m(MovementKind.receipt, 2, 4),
      m(MovementKind.baseline, 10, 5), // новая точка отсчёта
    ], from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 9))['milk']!;
    expect(l.consumption, 0);
    expect(l.end, 10);
  });

  test('движения после конца периода не учитываются', () {
    final l = StockLedger.compute([
      m(MovementKind.baseline, 10, 1),
      m(MovementKind.receipt, 6, 20),
    ], from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 9))['milk']!;
    expect(l.received, 0);
    expect(l.end, 10);
  });
}
