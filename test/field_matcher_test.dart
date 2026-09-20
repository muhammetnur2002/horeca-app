import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/custom_template/data/field_matcher.dart';
import 'package:horeca_app/features/custom_template/data/template_models.dart';

void main() {
  test('точное совпадение по офлайн-словарю даёт максимальную уверенность',
      () {
    final (field, confidence) = FieldMatcher.matchField('Наименование');
    expect(field, TemplateField.productName);
    expect(confidence, 1.0);
  });

  test('заголовок с завершающей точкой всё равно матчится точно', () {
    // Раньше отсутствие финального trim() после замены "." на пробел
    // превращало точное совпадение в частичное (confidence 0.85).
    final (field, confidence) = FieldMatcher.matchField('Ед. изм.');
    expect(field, TemplateField.unit);
    expect(confidence, 1.0);
  });

  test('нераспознанный заголовок не сопоставляется ни с чем', () {
    final (field, confidence) = FieldMatcher.matchField('Дата поставки');
    expect(field, TemplateField.notUsed);
    expect(confidence, 0.0);
  });

  test('автосопоставление колонок не отдаёт одно поле двум колонкам', () {
    // Оба заголовка похожи на "название" — второй должен остаться
    // notUsed, а не переопределить уже занятое поле.
    final mappings =
        FieldMatcher.autoMatchColumns(['Наименование', 'Название товара']);
    final matchedFields =
        mappings.where((m) => m.mappedField != TemplateField.notUsed).toList();
    expect(matchedFields, hasLength(1));
    expect(matchedFields.first.mappedField, TemplateField.productName);
  });

  test('автосопоставление распознаёт разные поля в разных колонках', () {
    final mappings = FieldMatcher.autoMatchColumns(
        ['Наименование', 'Количество', 'Ед. изм.', 'Категория', 'Отдел']);
    expect(mappings[0].mappedField, TemplateField.productName);
    expect(mappings[1].mappedField, TemplateField.quantity);
    expect(mappings[2].mappedField, TemplateField.unit);
    expect(mappings[3].mappedField, TemplateField.category);
    expect(mappings[4].mappedField, TemplateField.department);
  });
}
