class ProductModel {
  final String id;
  String name;
  String unit;           // основная единица (для заявок)
  String inventoryUnit;  // единица для инвентаризации
  String categoryId;

  ProductModel({
    required this.id,
    required this.name,
    required this.unit,
    String? inventoryUnit,
    required this.categoryId,
  }) : inventoryUnit = inventoryUnit ?? unit;
}