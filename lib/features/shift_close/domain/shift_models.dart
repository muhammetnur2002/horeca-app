/// Модели закрытия смены.
///
/// Раньше они жили прямо в shift_close_screen.dart, и слой data
/// (shift_draft_provider) импортировал presentation — циклическая
/// зависимость и нарушение слоёв.
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
