enum TemplateField {
  productName,
  quantity,
  unit,
  category,
  department,
  notUsed,
}

extension TemplateFieldExt on TemplateField {
  String get label {
    switch (this) {
      case TemplateField.productName: return 'Название товара';
      case TemplateField.quantity: return 'Остаток / Количество';
      case TemplateField.unit: return 'Единица измерения';
      case TemplateField.category: return 'Категория';
      case TemplateField.department: return 'Отдел';
      case TemplateField.notUsed: return 'Не использовать';
    }
  }
}

class ColumnMapping {
  final String originalHeader;
  final int columnIndex;
  TemplateField mappedField;
  double confidence; // 0.0 - 1.0, насколько уверен авто-словарь

  ColumnMapping({
    required this.originalHeader,
    required this.columnIndex,
    this.mappedField = TemplateField.notUsed,
    this.confidence = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'originalHeader': originalHeader,
    'columnIndex': columnIndex,
    'mappedField': mappedField.name,
  };

  factory ColumnMapping.fromJson(Map<String, dynamic> json) => ColumnMapping(
    originalHeader: json['originalHeader'] as String,
    columnIndex: json['columnIndex'] as int,
    mappedField: TemplateField.values.firstWhere(
        (e) => e.name == json['mappedField'], orElse: () => TemplateField.notUsed),
  );
}

class CustomTemplate {
  final String name;
  final List<ColumnMapping> columns;
  final DateTime createdAt;

  CustomTemplate({required this.name, required this.columns, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'name': name,
    'columns': columns.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomTemplate.fromJson(Map<String, dynamic> json) => CustomTemplate(
    name: json['name'] as String,
    columns: (json['columns'] as List).map((c) => ColumnMapping.fromJson(c)).toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
