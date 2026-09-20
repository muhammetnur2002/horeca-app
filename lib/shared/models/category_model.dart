class CategoryModel {
  final String id;
  String name;
  String departmentId;

  /// Явный флаг "эта категория — десерты": показывать её товары в шаге
  /// "Смена и списания" при закрытии смены. Раньше это угадывалось по
  /// названию (искали подстроку "десерт"), но так ломалось на любом
  /// написании, отличном от точного корня — "Desert", "деСерт" с опечаткой,
  /// "дессерт" с двумя "с" и т.д. Теперь это просто переключатель, который
  /// администратор включает у нужной категории один раз, и он не зависит
  /// от того, как категория называется.
  bool isDessertCategory;

  CategoryModel({
    required this.id,
    required this.name,
    required this.departmentId,
    this.isDessertCategory = false,
  });
}
