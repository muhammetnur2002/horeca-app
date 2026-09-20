/// Данные экрана "Закрытие смены".
///
/// Вынесено из shift_close_screen.dart, чтобы модели не терялись
/// среди виджетов и логики экрана.
library;

/// Один десерт с остатками на витрине/складе и списанием за смену.
class DessertItem {
  final String name;
  int showcase;
  int stock;
  int writeOff;

  DessertItem({
    required this.name,
    this.showcase = 0,
    this.stock = 0,
    this.writeOff = 0,
  });
}

/// Списание, добавленное вручную (не из категории "Десерты").
class ManualWriteOff {
  String name;
  int quantity;
  String unit;

  ManualWriteOff({
    required this.name,
    this.quantity = 1,
    this.unit = 'шт',
  });
}
