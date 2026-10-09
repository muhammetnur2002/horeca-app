import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/inventory/presentation/inventory_save.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/consumption.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';

// Четыре ошибки ядра из аудита: расход iiko одной датой, смешанные единицы,
// инвентаризация только по PDF. Кнопка синхронизации проверяется вручную:
// без Firestore её не прогнать.

class _NoSync extends CloudAutoSync {
  _NoSync(super.ref);
  @override
  void scheduleSync() {}
}

StockMove _move(String id, DateTime at, StockMoveKind kind, double qty,
        {String unit = 'кг', String key = 'p1'}) =>
    StockMove(
      id: id,
      at: at,
      productKey: key,
      name: 'Мука',
      unit: unit,
      kind: kind,
      qty: qty,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('единицы', () {
    test('граммы считаются в кг, штуки к кг не прибавляются', () {
      final moves = [
        _move('1', DateTime(2026, 10, 1), StockMoveKind.count, 2),
        _move('2', DateTime(2026, 10, 2), StockMoveKind.receipt, 500, unit: 'г'),
        _move('3', DateTime(2026, 10, 3), StockMoveKind.writeOff, 1, unit: 'шт'),
      ];
      expect(balanceAt(moves, DateTime(2026, 10, 4)), closeTo(2.5, 1e-9));
      expect(hasMixedUnits(moves), isTrue);

      final row = buildStockReport(
        moves: moves,
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 4),
      ).single;
      expect(row.unit, 'кг');
      expect(row.incoming, closeTo(0.5, 1e-9));
      expect(row.writeOff, 0);
      expect(row.closing, closeTo(2.5, 1e-9));
      expect(row.mixedUnits, isTrue);
    });

    test('списание со смены пишется в единице товара', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SupplyRepository(prefs, '01');
      repo.recordWriteOffs(
        at: DateTime(2026, 10, 9),
        batchId: 'shift-1',
        quantities: {'Сливки': 0.5, 'Чизкейк': 2},
        unitFor: (name) => name == 'Сливки' ? 'л' : '',
      );
      final units = {for (final m in repo.state.moves) m.name: m.unit};
      expect(units, {'Сливки': 'л', 'Чизкейк': 'шт'});
    });
  });

  group('расход iiko по дням', () {
    final cards = {
      'блин': const [
        CardIngredient(productKey: 'p1', name: 'Мука', unit: 'кг', amountPerPortion: 0.5),
      ],
    };

    test('продажи из iiko приходят по дням', () {
      final sales = parseOlapSales({
        'data': [
          {'DishName': 'Блин', 'OpenDate.Typed': '2026-10-01', 'DishAmountInt': 2},
          {'DishName': 'Блин', 'OpenDate.Typed': '2026-10-02T00:00:00', 'DishAmountInt': 4},
        ],
      });
      expect(
        {for (final s in sales) s.day: s.qty},
        {DateTime(2026, 10, 1): 2.0, DateTime(2026, 10, 2): 4.0},
      );
    });

    test('расход до пересчёта внутри срока не вычитается второй раз', () {
      final daily = dailyConsumptionMoves(
        sales: [
          for (var d = 1; d <= 5; d++)
            DishSale(name: 'Блин', qty: 4, day: DateTime(2026, 10, d)),
        ],
        cardsByDish: cards,
        keyFor: (_) => 'p1',
      );
      expect(daily.moves, hasLength(5));
      expect(daily.moves.first.at, DateTime(2026, 10, 1));

      // Пересчёт вечером 3-го: 10 кг. Дальше расход 4-го и 5-го по 2 кг.
      final moves = [
        _move('c', DateTime(2026, 10, 3, 22), StockMoveKind.count, 10),
        ...daily.moves,
      ];
      expect(balanceAt(moves, DateTime(2026, 10, 5, 23)), closeTo(6, 1e-9));
    });

    test('продажи без дня в остаток не идут', () {
      final daily = dailyConsumptionMoves(
        sales: const [DishSale(name: 'Блин', qty: 4)],
        cardsByDish: cards,
        keyFor: (_) => 'p1',
      );
      expect(daily.moves, isEmpty);
      expect(daily.undatedSales, 1);
    });

    test('короткий запрос не стирает расход длинного за другие дни', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SupplyRepository(prefs, '01');
      List<StockMove> days(int from, int to, double qty) => [
            for (var d = from; d <= to; d++)
              _move('iiko:$d', DateTime(2026, 10, d), StockMoveKind.consumption, qty),
          ];
      repo.replaceConsumption(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 10, 18),
        consumption: days(1, 10, 1),
      );
      repo.replaceConsumption(
        from: DateTime(2026, 10, 8),
        to: DateTime(2026, 10, 10, 20),
        consumption: days(8, 10, 3),
      );
      final total = repo.state.moves.fold<double>(0, (sum, m) => sum + m.qty);
      expect(repo.state.moves, hasLength(10));
      expect(total, 7 * 1 + 3 * 3);
    });
  });

  group('инвентаризация', () {
    Future<ProviderContainer> container() async {
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cloudAutoSyncProvider.overrideWith((ref) => _NoSync(ref)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    InventoryState report(double flour) => InventoryState(
          step: 3,
          departmentId: '1',
          items: [
            InventoryItem(productId: 'p1', productName: 'Мука', remaining: flour, unit: 'кг'),
          ],
        );

    test('копировать, поделиться и PDF сохраняют пересчёт один раз', () async {
      final c = await container();
      final state = report(6);
      for (var i = 0; i < 3; i++) {
        saveInventoryOnce(c.read, state: state, title: 'Инвентаризация Кухня', text: 'отчёт');
      }
      expect(c.read(historyRepositoryProvider).getAll(), hasLength(1));
      final counts = c
          .read(supplyRepositoryProvider)
          .moves
          .where((m) => m.kind == StockMoveKind.count);
      expect(counts, hasLength(1));
      expect(counts.single.qty, 6);
    });

    test('после правки отчёт сохраняется заново', () async {
      final c = await container();
      saveInventoryOnce(c.read, state: report(6), title: 't', text: 'a',
          now: DateTime(2026, 10, 9, 20));
      final saved = saveInventoryOnce(c.read, state: report(7), title: 't', text: 'b',
          now: DateTime(2026, 10, 9, 21));
      expect(saved, isTrue);
      expect(c.read(historyRepositoryProvider).getAll(), hasLength(2));
      expect(
        balanceAt(c.read(supplyRepositoryProvider).moves, DateTime(2026, 10, 10)),
        7,
      );
    });
  });
}
