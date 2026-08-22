/// Небольшие форматтеры для экрана "Закрытие смены".
/// Вынесены отдельно, т.к. использовались во всех шагах и раздували
/// основной файл экрана.
library;

/// Форматирует сумму с разделением разрядов пробелом: 12000 -> "12 000".
String shiftCloseFormatMoney(double value) {
  if (value == 0) return '0';
  return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}

/// Сегодняшняя дата в формате "12 августа 2026".
String shiftCloseFormattedDate() {
  final now = DateTime.now();
  const months = [
    '',
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${now.day} ${months[now.month]} ${now.year}';
}
