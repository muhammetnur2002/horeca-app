/// Работа с денежными суммами.
///
/// Раньше суммы разбирались напрямую через `double.tryParse`:
///  * запятая как десятичный разделитель давала null, то есть ноль
///    («1,5» превращалось в 0 — выручка терялась молча);
///  * сложение double накапливало ошибку (0.1 + 0.2 = 0.30000000000000004).
class Money {
  const Money._();

  /// Обычное десятичное число со знаком — без экспоненты.
  static final RegExp _plainDecimal = RegExp(r'^-?\d*\.?\d*$');

  /// Разбирает введённую пользователем сумму.
  /// Понимает запятую, пробелы и неразрывные пробелы.
  static double parse(String? raw) {
    if (raw == null) return 0;
    final cleaned = raw.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
    if (cleaned.isEmpty) return 0;

    final value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite) return 0;

    // Округляем по десятичным знакам исходной строки, а не через двоичное
    // умножение: 1.005 в double хранится как 1.00499..., и (v * 100).round()
    // дал бы 1.00 вместо ожидаемых 1.01.
    if (!_plainDecimal.hasMatch(cleaned)) return round(value);
    return _roundDecimalString(cleaned);
  }

  static double _roundDecimalString(String s) {
    final negative = s.startsWith('-');
    final body = negative ? s.substring(1) : s;

    final dot = body.indexOf('.');
    if (dot == -1) return negative ? -double.parse(body) : double.parse(body);

    final intText = body.substring(0, dot);
    final fraction = body.substring(dot + 1);
    if (fraction.length <= 2) return double.parse(s);

    final units = intText.isEmpty ? 0 : int.parse(intText);
    final keptText = fraction.substring(0, 2).padRight(2, '0');
    var cents = units * 100 + int.parse(keptText);

    // Половина сотой и больше — округляем вверх.
    if (fraction.codeUnitAt(2) - 0x30 >= 5) cents += 1;

    final result = cents / 100;
    return negative ? -result : result;
  }

  /// Округление до сотых для результатов вычислений.
  ///
  /// toStringAsFixed выполняет корректное десятичное округление и убирает
  /// накопленный «хвост» double.
  static double round(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return double.parse(value.toStringAsFixed(2));
  }

  /// Сложение с округлением на каждом шаге.
  static double sum(Iterable<double> values) =>
      round(values.fold<double>(0, (a, b) => round(a + b)));

  /// Отображение суммы: без лишних нулей, с разделителем тысяч.
  static String format(double value) {
    final rounded = round(value);
    final isWhole = rounded == rounded.truncateToDouble();
    final text =
        isWhole ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(2);

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

/// «184300.5» → «184 300».
String formatMoney(double v) {
  final s = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}
