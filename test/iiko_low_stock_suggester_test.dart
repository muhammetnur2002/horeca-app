import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/iiko/data/iiko_request_suggester.dart';
import 'package:horeca_app/features/iiko/data/iiko_service.dart';
import 'package:horeca_app/shared/models/product_model.dart';

void main() {
  ProductModel product({
    required String id,
    required String name,
    double? minStock,
    String unit = 'шт',
  }) =>
      ProductModel(
          id: id, name: name, unit: unit, categoryId: 'c1', minStock: minStock);

  IikoBalanceItem balance(String name, double amount, {String unit = 'шт'}) =>
      IikoBalanceItem(productName: name, amount: amount, unit: unit);

  test('товар без minStock игнорируется, даже если остаток нулевой', () {
    final result = buildLowStockSuggestions(
      balances: [balance('Кофе', 0)],
      products: [product(id: '1', name: 'Кофе')],
    );
    expect(result, isEmpty);
  });

  test('товар без совпадения по названию в остатках iiko пропускается', () {
    final result = buildLowStockSuggestions(
      balances: [balance('Молоко', 1)],
      products: [product(id: '1', name: 'Кофе', minStock: 5)],
    );
    expect(result, isEmpty);
  });

  test('остаток выше или равен minStock — дозаказ не предлагается', () {
    final result = buildLowStockSuggestions(
      balances: [balance('Сахар', 5)],
      products: [product(id: '1', name: 'Сахар', minStock: 5)],
    );
    expect(result, isEmpty);
  });

  test('сопоставление по названию не зависит от регистра и пробелов', () {
    final result = buildLowStockSuggestions(
      balances: [balance('  КОФЕ зерновой  ', 1)],
      products: [product(id: '1', name: 'кофе Зерновой', minStock: 3)],
    );
    expect(result, hasLength(1));
    expect(result.first.product.id, '1');
  });

  test('остаток ниже minStock — предлагается дозаказ до уровня minStock', () {
    final result = buildLowStockSuggestions(
      balances: [balance('Молоко', 2)],
      products: [product(id: '1', name: 'Молоко', minStock: 5)],
    );
    expect(result, hasLength(1));
    expect(result.first.suggestedQuantity, 3);
  });

  test('минимальный дозаказ — 1 единица, даже если дефицит меньше', () {
    final result = buildLowStockSuggestions(
      balances: [balance('Сироп', 4.7)],
      products: [product(id: '1', name: 'Сироп', minStock: 5)],
    );
    expect(result, hasLength(1));
    expect(result.first.suggestedQuantity, 1);
  });

  test('несколько товаров ниже минимума — все попадают в список', () {
    final result = buildLowStockSuggestions(
      balances: [balance('Кофе', 1), balance('Молоко', 1), balance('Сахар', 10)],
      products: [
        product(id: '1', name: 'Кофе', minStock: 3),
        product(id: '2', name: 'Молоко', minStock: 4),
        product(id: '3', name: 'Сахар', minStock: 3),
      ],
    );
    expect(result.map((s) => s.product.id), containsAll(['1', '2']));
    expect(result.map((s) => s.product.id), isNot(contains('3')));
  });
}
