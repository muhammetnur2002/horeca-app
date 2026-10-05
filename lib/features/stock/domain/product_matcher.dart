/// Сопоставление названия из накладной с товаром каталога.
///
/// В накладной товар обычно записан иначе, чем в каталоге: «Молоко
/// ультрапаст. 3,2% 1л Простоквашино» против «Молоко 3,2%». Сравниваем
/// по общим словам и числам, без учёта регистра, «ё» и знаков.
library;

abstract final class ProductMatcher {
  /// Единицы измерения при сравнении не учитываем — они почти всегда
  /// совпадают и только мешают.
  static const _noise = {
    'шт', 'кг', 'гр', 'г', 'л', 'мл', 'уп', 'упак', 'бут', 'пач', 'кор',
    'коробка', 'упаковка', 'pcs', 'kg', 'ml',
  };

  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}')
      // «33 %» и «33%» — одно и то же.
      .replaceAllMapped(RegExp(r'(\d)\s+%'), (m) => '${m[1]}%')
      .replaceAll(RegExp(r'[^a-zа-я0-9.%]+'), ' ')
      .trim();

  static Set<String> tokens(String s) => normalize(s)
      .split(' ')
      .map((t) => t.replaceAll(RegExp(r'^\.+|\.+$'), ''))
      .where((t) =>
          t.isNotEmpty &&
          !_noise.contains(t) &&
          (t.length >= 2 || RegExp(r'\d').hasMatch(t)))
      .toSet();

  /// Похожесть 0..1: доля слов каталожного названия, найденных в названии
  /// из накладной (каталожное обычно короче), плюс бонус за полное
  /// вхождение. Слова длиной от 4 букв совпадают и по общему началу
  /// («стакан» / «стаканы»).
  static double score(String recognized, String catalog) {
    final a = tokens(recognized), b = tokens(catalog);
    if (a.isEmpty || b.isEmpty) return 0;
    var hit = 0;
    for (final t in b) {
      if (a.contains(t) ||
          a.any((x) =>
              x.length >= 4 &&
              t.length >= 4 &&
              (x.startsWith(t) || t.startsWith(x)))) {
        hit++;
      }
    }
    final coverage = hit / b.length;
    final whole = normalize(recognized).contains(normalize(catalog)) ? 0.15 : 0;
    return (coverage + whole).clamp(0, 1).toDouble();
  }

  /// Лучший товар каталога для названия или null, если ничего похожего.
  static T? bestMatch<T>(
    String recognized,
    Iterable<T> catalog,
    String Function(T) nameOf, {
    double threshold = 0.6,
  }) {
    T? best;
    var bestScore = 0.0;
    for (final item in catalog) {
      final s = score(recognized, nameOf(item));
      if (s > bestScore) {
        bestScore = s;
        best = item;
      }
    }
    return bestScore >= threshold ? best : null;
  }
}
