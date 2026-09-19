/// Сопоставляет остатки iiko с товарами каталога (по названию, без учёта
/// регистра/пробелов) и предлагает заявку на те, что ниже minStock.
/// Раньше это было в списке незавершённых задач проекта — единственный
/// способ связать данные iiko с внутренним каталогом, так как API iiko
/// не знает о ProductModel.id, только о названии.
library;

import 'package:horeca_app/features/iiko/data/iiko_service.dart';
import 'package:horeca_app/shared/models/product_model.dart';

class LowStockSuggestion {
  final ProductModel product;
  final double currentAmount;
  final String iikoUnit;
  final double suggestedQuantity;

  const LowStockSuggestion({
    required this.product,
    required this.currentAmount,
    required this.iikoUnit,
    required this.suggestedQuantity,
  });
}

String _normalize(String s) => s.trim().toLowerCase();

List<LowStockSuggestion> buildLowStockSuggestions({
  required List<IikoBalanceItem> balances,
  required List<ProductModel> products,
}) {
  final balanceByName = <String, IikoBalanceItem>{
    for (final b in balances) _normalize(b.productName): b,
  };

  final suggestions = <LowStockSuggestion>[];
  for (final product in products) {
    final minStock = product.minStock;
    if (minStock == null) continue;

    final match = balanceByName[_normalize(product.name)];
    if (match == null) continue;
    if (match.amount >= minStock) continue;

    final deficit = minStock - match.amount;
    // Дозаказываем с запасом до уровня minStock, минимум 1 единица —
    // "долить ровно до минимума" на практике слишком мало для реального заказа.
    final suggestedQuantity = deficit < 1 ? 1.0 : deficit.ceilToDouble();

    suggestions.add(LowStockSuggestion(
      product: product,
      currentAmount: match.amount,
      iikoUnit: match.unit,
      suggestedQuantity: suggestedQuantity,
    ));
  }
  return suggestions;
}
