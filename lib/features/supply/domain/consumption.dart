/// Расход ингредиентов = продажи блюд × техкарта.
/// Блюдо без техкарты в остаток не пишется: цифру нельзя выдумать.
library;

import 'package:horeca_app/features/supply/domain/stock_ledger.dart';

class DishSale {
  final String name;
  final double qty;

  /// День продажи (без времени). null — iiko не сказал, в какой день.
  final DateTime? day;
  const DishSale({required this.name, required this.qty, this.day});
}

class CardIngredient {
  final String productKey;
  final String name;
  final String unit;
  final double amountPerPortion;
  const CardIngredient({
    required this.productKey,
    required this.name,
    required this.unit,
    required this.amountPerPortion,
  });
}

class IngredientUse {
  final String productKey;
  final String name;
  final String unit;
  final double qty;
  const IngredientUse({
    required this.productKey,
    required this.name,
    required this.unit,
    required this.qty,
  });
}

class ConsumptionExpand {
  final List<IngredientUse> ingredients;
  final List<String> dishesWithoutCard;
  const ConsumptionExpand({
    required this.ingredients,
    required this.dishesWithoutCard,
  });
}

String _norm(String raw) => raw.trim().toLowerCase().replaceAll('ё', 'е');

ConsumptionExpand expandSales({
  required List<DishSale> sales,
  required Map<String, List<CardIngredient>> cardsByDish,
}) {
  final totals = <String, IngredientUse>{};
  final missing = <String>[];
  for (final sale in sales) {
    if (sale.qty <= 0 || sale.name.trim().isEmpty) continue;
    final card = cardsByDish[_norm(sale.name)];
    if (card == null || card.isEmpty) {
      missing.add(sale.name);
      continue;
    }
    for (final item in card) {
      if (item.amountPerPortion <= 0) continue;
      final qty = item.amountPerPortion * sale.qty;
      final previous = totals[item.productKey];
      if (previous == null) {
        totals[item.productKey] = IngredientUse(
          productKey: item.productKey,
          name: item.name,
          unit: item.unit,
          qty: qty,
        );
      } else {
        totals[item.productKey] = IngredientUse(
          productKey: previous.productKey,
          name: previous.name,
          unit: previous.unit,
          qty: previous.qty + qty,
        );
      }
    }
  }
  final ingredients = totals.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return ConsumptionExpand(ingredients: ingredients, dishesWithoutCard: missing);
}

List<DishSale> parseOlapSales(dynamic body) {
  final rows = _rows(body);
  final byKey = <(String, DateTime?), double>{};
  for (final row in rows) {
    final name = (row['DishName'] ?? row['dishName'] ?? '').toString().trim();
    final qtyRaw = row['DishAmountInt'] ?? row['DishAmount'] ?? row['amount'];
    final qty = qtyRaw is num ? qtyRaw.toDouble() : double.tryParse('$qtyRaw');
    if (name.isEmpty || qty == null || qty <= 0) continue;
    final day = _saleDay(row['OpenDate.Typed'] ?? row['OpenDate'] ?? row['Date']);
    byKey[(name, day)] = (byKey[(name, day)] ?? 0) + qty;
  }
  return [
    for (final entry in byKey.entries)
      DishSale(name: entry.key.$1, qty: entry.value, day: entry.key.$2),
  ];
}

DateTime? _saleDay(Object? raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.length < 10) return null;
  final parsed = DateTime.tryParse(text.substring(0, 10));
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

class DailyConsumption {
  final List<StockMove> moves;
  final List<String> dishesWithoutCard;

  /// Продажи без дня. В остаток не идут: неизвестно, до пересчёта они
  /// были или после.
  final int undatedSales;
  const DailyConsumption({
    required this.moves,
    required this.dishesWithoutCard,
    required this.undatedSales,
  });
}

/// Расход по дням: одно движение на ингредиент за каждый день продаж.
///
/// Движение ставится на начало дня. Пересчёт в тот же день (обычно на
/// закрытии) заменяет остаток и этот день уже не вычитает второй раз.
/// Расход до пересчёта внутри срока тоже не вычитается: пересчёт новее.
DailyConsumption dailyConsumptionMoves({
  required List<DishSale> sales,
  required Map<String, List<CardIngredient>> cardsByDish,
  required String Function(String ingredientName) keyFor,
}) {
  final byDay = <DateTime, List<DishSale>>{};
  var undated = 0;
  for (final sale in sales) {
    final day = sale.day;
    if (day == null) {
      undated++;
      continue;
    }
    byDay.putIfAbsent(day, () => []).add(sale);
  }
  final moves = <StockMove>[];
  final missing = <String>{};
  final days = byDay.keys.toList()..sort();
  for (final day in days) {
    final expanded = expandSales(sales: byDay[day]!, cardsByDish: cardsByDish);
    missing.addAll(expanded.dishesWithoutCard);
    final stamp = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    for (final item in expanded.ingredients) {
      final key = keyFor(item.name);
      moves.add(StockMove(
        id: 'iiko:$stamp:$key',
        at: day,
        productKey: key,
        name: item.name,
        unit: item.unit,
        kind: StockMoveKind.consumption,
        qty: item.qty,
      ));
    }
  }
  return DailyConsumption(
    moves: moves,
    dishesWithoutCard: missing.toList()..sort(),
    undatedSales: undated,
  );
}

/// Техкарты: имя блюда → ингредиенты на 1 порцию.
/// [productNames] — id номенклатуры iiko → человеческое имя.
Map<String, List<CardIngredient>> parseAssemblyCharts(
  dynamic body,
  Map<String, String> productNames,
) {
  final charts = body is Map && body['assemblyCharts'] is List
      ? body['assemblyCharts'] as List
      : body is List
          ? body
          : const [];
  final out = <String, List<CardIngredient>>{};
  for (final raw in charts) {
    if (raw is! Map) continue;
    final productId = (raw['assembledProductId'] ?? raw['productId'] ?? '').toString();
    final dishName = (raw['productName'] ?? productNames[productId] ?? '').toString().trim();
    if (dishName.isEmpty) continue;
    final assembledRaw = raw['assembledAmount'] ?? raw['assembledQuantity'];
    final per = assembledRaw is num && assembledRaw > 0 ? assembledRaw.toDouble() : 1.0;
    final items = raw['items'] as List? ?? const [];
    final card = <CardIngredient>[];
    for (final item in items) {
      if (item is! Map) continue;
      final ingredientId = (item['productId'] ?? item['product'] ?? '').toString();
      final amountRaw = item['amount'] ?? item['amountOut'];
      final amount = amountRaw is num ? amountRaw.toDouble() : double.tryParse('$amountRaw');
      if (amount == null || amount <= 0) continue;
      final name = (item['productName'] ?? productNames[ingredientId] ?? ingredientId).toString();
      if (name.trim().isEmpty) continue;
      card.add(CardIngredient(
        productKey: ingredientId.isEmpty ? _norm(name) : ingredientId,
        name: name,
        unit: (item['unit'] ?? item['amountUnit'] ?? 'шт').toString(),
        amountPerPortion: amount / per,
      ));
    }
    if (card.isNotEmpty) out[_norm(dishName)] = card;
  }
  return out;
}

List<Map<String, dynamic>> _rows(dynamic body) {
  if (body is List) {
    return [
      for (final row in body)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }
  if (body is Map && body['data'] is List) {
    return [
      for (final row in body['data'] as List)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }
  return const [];
}
