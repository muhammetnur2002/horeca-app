import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/account/data/cloud_sync_merge.dart';
import 'package:horeca_app/features/supply/domain/consumption.dart';
import 'package:horeca_app/features/supply/domain/invoice_parse.dart';
import 'package:horeca_app/features/supply/domain/ocr_quota.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';
import 'package:horeca_app/features/supply/domain/supply_models.dart';

void main() {
  SupplyLine line(String name, double qty, {String unit = 'шт', String productId = ''}) {
    return SupplyLine(name: name, quantity: qty, unit: unit, productId: productId);
  }

  test('сверка отличает пришло, меньше, нет и лишнее', () {
    final rows = matchDelivery(
      ordered: [
        line('Молоко', 10, unit: 'л', productId: 'p1'),
        line('Сахар', 2, unit: 'кг', productId: 'p2'),
        line('Кофе', 1, unit: 'кг', productId: 'p3'),
      ],
      arrived: [
        line('молоко', 10, unit: 'л'),
        line('Сахар', 1, unit: 'кг'),
        line('Сироп', 3, unit: 'шт'),
      ],
    );
    expect(rows.map((e) => e.status), [
      ReceiptStatus.matched,
      ReceiptStatus.short,
      ReceiptStatus.missing,
      ReceiptStatus.extra,
    ]);
    expect(rows.first.productId, 'p1');
    expect(rows.last.orderedQty, 0);
    expect(rows.last.name, 'Сироп');
  });

  test('ё и е в названии — одна позиция', () {
    final rows = matchDelivery(
      ordered: [line('Чёрный чай', 1)],
      arrived: [line('Черный чай', 1)],
    );
    expect(rows.single.status, ReceiptStatus.matched);
  });

  test('для сверки берётся вчерашняя заявка, а не сегодняшняя', () {
    final now = DateTime(2026, 10, 9, 15);
    final picked = pickRequestToReceive([
      SupplyRequest(
        id: 'today',
        createdAt: DateTime(2026, 10, 9, 9),
        departmentLabel: 'Бар',
        lines: [line('Стакан', 1)],
      ),
      SupplyRequest(
        id: 'yesterday',
        createdAt: DateTime(2026, 10, 8, 18),
        departmentLabel: 'Кухня',
        lines: [line('Молоко', 2)],
      ),
    ], now);
    expect(picked?.id, 'yesterday');
  });

  test('остаток = факт инвентаризации + приход − расход − списания', () {
    final countAt = DateTime(2026, 10, 1, 12);
    final later = DateTime(2026, 10, 2, 12);
    final moves = [
      StockMove(
        id: 'c',
        at: countAt,
        productKey: 'milk',
        name: 'Молоко',
        unit: 'л',
        kind: StockMoveKind.count,
        qty: 10,
      ),
      StockMove(
        id: 'r',
        at: later,
        productKey: 'milk',
        name: 'Молоко',
        unit: 'л',
        kind: StockMoveKind.receipt,
        qty: 4,
      ),
      StockMove(
        id: 'u',
        at: later.add(const Duration(hours: 1)),
        productKey: 'milk',
        name: 'Молоко',
        unit: 'л',
        kind: StockMoveKind.consumption,
        qty: 3,
      ),
      StockMove(
        id: 'w',
        at: later.add(const Duration(hours: 2)),
        productKey: 'milk',
        name: 'Молоко',
        unit: 'л',
        kind: StockMoveKind.writeOff,
        qty: 1,
      ),
    ];
    expect(balanceAt(moves, later.add(const Duration(hours: 3))), 10);
  });

  test('метки: плохо, мало, норма, много', () {
    expect(markStock(balance: 0, minimum: 2), StockMark.bad);
    expect(markStock(balance: 1, minimum: 2), StockMark.low);
    expect(markStock(balance: 2, minimum: 2), StockMark.stable);
    expect(markStock(balance: 6, minimum: 2), StockMark.high);
    expect(markStock(balance: 4, minimum: null), StockMark.stable);
  });

  test('отчёт за неделю не тащит приход из другого месяца в колонку прихода', () {
    final rows = buildStockReport(
      moves: [
        StockMove(
          id: 'old',
          at: DateTime(2026, 9, 1),
          productKey: 'milk',
          name: 'Молоко',
          unit: 'л',
          kind: StockMoveKind.receipt,
          qty: 5,
        ),
        StockMove(
          id: 'new',
          at: DateTime(2026, 10, 8),
          productKey: 'milk',
          name: 'Молоко',
          unit: 'л',
          kind: StockMoveKind.receipt,
          qty: 2,
        ),
      ],
      from: DateTime(2026, 10, 2),
      to: DateTime(2026, 10, 9),
      minimums: {'milk': 2},
    );
    expect(rows.single.opening, 5);
    expect(rows.single.incoming, 2);
    expect(rows.single.closing, 7);
    expect(rows.single.mark, StockMark.high);
  });

  test('квота обнуляется на следующий день и держит 10', () {
    final today = DateTime(2026, 10, 9, 8);
    final fresh = OcrQuota.fromJson({'day': '2026-10-08', 'used': 10}, today);
    expect(fresh.canRecognize, isTrue);
    var quota = OcrQuota.fresh(today);
    for (var i = 0; i < OcrQuota.dailyLimit; i++) {
      expect(quota.canRecognize, isTrue);
      quota = quota.consume();
    }
    expect(quota.canRecognize, isFalse);
    expect(quota.left, 0);
  });

  test('таблица из ответа модели читается даже с пояснением', () {
    final lines = parseInvoiceTable('''
Вот накладная:
```json
[{"name":"Молоко","qty":2.5,"unit":"л"},{"name":"","qty":1}]
```
''');
    expect(lines.single.name, 'Молоко');
    expect(lines.single.quantity, 2.5);
    expect(lines.single.unit, 'л');
  });

  test('расход считается по техкарте, блюдо без карты не выдумывается', () {
    final result = expandSales(
      sales: [
        const DishSale(name: 'Латте', qty: 2),
        const DishSale(name: 'Чизкейк', qty: 4),
      ],
      cardsByDish: {
        'латте': [
          const CardIngredient(
            productKey: 'milk',
            name: 'Молоко',
            unit: 'л',
            amountPerPortion: 0.2,
          ),
        ],
      },
    );
    expect(result.ingredients.single.qty, closeTo(0.4, 0.0001));
    expect(result.dishesWithoutCard, ['Чизкейк']);
  });

  test('продажи и техкарты разбираются из ответа iiko', () {
    final sales = parseOlapSales({
      'data': [
        {'DishName': 'Латте', 'DishAmountInt': 2},
        {'DishName': 'Латте', 'DishAmountInt': 1},
      ],
    });
    expect(sales.single.qty, 3);
    final cards = parseAssemblyCharts({
      'assemblyCharts': [
        {
          'assembledProductId': 'dish',
          'assembledAmount': 2,
          'items': [
            {'productId': 'milk', 'amount': 0.4},
          ],
        },
      ],
    }, {'dish': 'Латте', 'milk': 'Молоко'});
    expect(cards['латте']!.single.amountPerPortion, closeTo(0.2, 0.0001));
    expect(cards['латте']!.single.name, 'Молоко');
  });

  test('заявки с двух телефонов соединяются, квота берёт больший счётчик', () {
    final requests = mergeSyncValue(
      key: 'supply_requests',
      local: jsonEncode([
        {'id': 'a', 'createdAt': '2026-10-08T10:00:00', 'lines': []}
      ]),
      cloud: jsonEncode([
        {'id': 'b', 'createdAt': '2026-10-07T10:00:00', 'lines': []}
      ]),
      localPending: true,
    );
    final ids = (jsonDecode(requests!) as List).map((e) => e['id']).toList();
    expect(ids, ['b', 'a']);

    final quota = jsonDecode(mergeSyncValue(
      key: 'ocr_quota',
      local: jsonEncode({'day': '2026-10-09', 'used': 4}),
      cloud: jsonEncode({'day': '2026-10-09', 'used': 7}),
      localPending: true,
    )!);
    expect(quota['used'], 7);

    final newer = jsonDecode(mergeSyncValue(
      key: 'ocr_quota',
      local: jsonEncode({'day': '2026-10-09', 'used': 1}),
      cloud: jsonEncode({'day': '2026-10-08', 'used': 9}),
      localPending: true,
    )!);
    expect(newer['day'], '2026-10-09');
  });
}
