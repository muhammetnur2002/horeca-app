/// Строка приёмки поставки.
class ReceiptLine {
  final String productId;
  final String productName;

  /// Единица заявки (в ней вводят, сколько пришло).
  final String unit;

  /// Сколько единиц инвентаризации в одной единице заявки.
  final double unitFactor;

  /// Сколько заказали по заявке (null — товар не из заявки).
  final double? ordered;

  /// Сколько пришло фактически, в единицах заявки.
  final double received;

  const ReceiptLine({
    required this.productId,
    required this.productName,
    required this.unit,
    this.unitFactor = 1,
    this.ordered,
    required this.received,
  });

  /// Недовоз (+) или перевоз (−) относительно заявки.
  double get shortage => (ordered ?? received) - received;
}
