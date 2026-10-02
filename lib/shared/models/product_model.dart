class ProductModel {
  final String id;
  String name;
  String unit;           // основная единица (для заявок)
  String inventoryUnit;  // единица для инвентаризации
  String categoryId;
  double? minStock;      // минимальный остаток для уведомления
  String? iikoProductId; // id товара в номенклатуре iiko
  /// Сколько единиц инвентаризации в одной единице заявки
  /// («1 коробка = 12 шт» → 12). Нужен, чтобы приход в коробках лёг
  /// в учёт в штуках.
  double unitFactor;
  ProductModel({
    required this.id,
    required this.name,
    required this.unit,
    String? inventoryUnit,
    required this.categoryId,
    this.minStock,
    this.iikoProductId,
    this.unitFactor = 1,
  }) : inventoryUnit = inventoryUnit ?? unit;
}
