/// Работа с денежными суммами.
///
/// Раньше суммы разбирались напрямую через `double.tryParse`:
///  * запятая как десятичный разделитель давала null, то есть ноль
///    («1,5» превращалось в 0 — выручка терялась молча);
///  * сложение double накапливало ошибку (0.1 + 0.2 = 0.30000000000000004).
class Money {
  const Money._();

  /// Разбирает введённую пользователем сумму.
  /// Понимает запятую, пробелы и неразрывные пробелы.
  static double parse(String? raw) {
    if (raw == null) return 0;
    final cleaned = raw
        .replaceAll(RegExp(r'[\s ]'), '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite) return 0;
    return round(value);
  }

  /// Округление до сотых — денежные суммы не хранят «хвосты» double.
  static double round(double value) => (value * 100).roundToDouble() / 100;

  /// Сложение с округлением на каждом шаге.
  static double sum(Iterable<double> values) =>
      round(values.fold<double>(0, (a, b) => round(a + b)));

  /// Отображение суммы: без лишних нулей, с разделителем тысяч.
  static String format(double value) {
    final rounded = round(value);
    final isWhole = rounded == rounded.truncateToDouble();
    final text = isWhole
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(2);

    final parts = text.split('.');
    final intPart = parts[0];
    final negative = intPart.startsWith('-');
    final digits = negative ? intPart.substring(1) : intPart;

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final grouped = (negative ? '-' : '') + buffer.toString();
    return parts.length > 1 ? '$grouped,${parts[1]}' : grouped;
  }
}
