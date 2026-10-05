/// Строка приёмки поставки.
class ReceiptLine {
  /// Товар каталога. null — строка из накладной, которую ещё не сопоставили
  /// с каталогом: она попадает в документ и отчёт, но не в остатки.
  final String? productId;
  final String productName;

  /// Единица заявки (в ней вводят, сколько пришло).
  final String unit;

  /// Сколько единиц инвентаризации в одной единице заявки.
  final double unitFactor;

  /// Сколько заказали по заявке (null — товар не из заявки).
  final double? ordered;

  /// Сколько пришло фактически, в единицах заявки.
  final double received;

  /// Цена за единицу по накладной/чеку, если известна.
  final double? price;

  const ReceiptLine({
    required this.productId,
    required this.productName,
    required this.unit,
    this.unitFactor = 1,
    this.ordered,
    required this.received,
    this.price,
  });

  /// Недовоз (+) или перевоз (−) относительно заявки.
  double get shortage => (ordered ?? received) - received;

  /// Сумма строки, если известна цена.
  double? get sum => price == null ? null : price! * received;
}
