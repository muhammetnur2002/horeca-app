import 'package:flutter/material.dart';

/// Иконки отделов сериализуются строковым ключом, а не числовым codePoint.
///
/// Раньше иконка восстанавливалась как `IconData(int.parse(...))`. Динамически
/// собранный IconData ломает tree-shaking шрифта иконок: `flutter build
/// --release` падает с «This application cannot tree shake icons fonts» и
/// требует `--no-tree-shake-icons`, что добавляет ~1.5 МБ к сборке.
class DepartmentIcons {
  const DepartmentIcons._();

  static const IconData fallback = Icons.category;
  static const String fallbackKey = 'category';

  /// Все иконки — константы, поэтому tree-shaking отрабатывает штатно.
  static const Map<String, IconData> byKey = <String, IconData>{
    'category': Icons.category,
    'kitchen': Icons.kitchen,
    'local_bar': Icons.local_bar,
    'table_restaurant': Icons.table_restaurant,
    'warehouse': Icons.warehouse,
    'cleaning_services': Icons.cleaning_services,
    'store': Icons.store,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'bakery_dining': Icons.bakery_dining,
    'soup_kitchen': Icons.soup_kitchen,
    'room_service': Icons.room_service,
    'inventory_2': Icons.inventory_2,
    'shopping_basket': Icons.shopping_basket,
    'ac_unit': Icons.ac_unit,
    'liquor': Icons.liquor,
    'help': Icons.help,
  };

  /// codePoint -> ключ. Нужно для чтения данных старого формата.
  static final Map<int, String> _keyByCodePoint = <int, String>{
    for (final e in byKey.entries) e.value.codePoint: e.key,
  };

  /// Восстанавливает иконку из сохранённого значения.
  /// Понимает и новый формат (ключ), и старый (codePoint строкой или числом).
  static IconData resolve(Object? raw) {
    if (raw is String) {
      final byName = byKey[raw];
      if (byName != null) return byName;
      final codePoint = int.tryParse(raw);
      if (codePoint != null) return _fromCodePoint(codePoint);
      return fallback;
    }
    if (raw is int) return _fromCodePoint(raw);
    return fallback;
  }

  static IconData _fromCodePoint(int codePoint) {
    final key = _keyByCodePoint[codePoint];
    return key == null ? fallback : byKey[key]!;
  }

  /// Ключ для сохранённого значения старого или нового формата
  /// (ключ, codePoint строкой или числом). Неизвестное — fallbackKey.
  static String keyOfStored(Object? raw) => keyOf(resolve(raw));

  /// Ключ для сохранения. Неизвестная иконка сохраняется как fallback.
  static String keyOf(IconData icon) =>
      _keyByCodePoint[icon.codePoint] ?? fallbackKey;
}
