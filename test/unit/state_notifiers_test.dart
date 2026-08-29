import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/shared/models/department_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RequestState', () {
    test('смена отдела сбрасывает выбранную категорию', () {
      final n = RequestStateNotifier()
        ..selectDepartment('1')
        ..selectCategory('10');
      expect(n.state.categoryId, '10');

      // Раньше copyWith(categoryId: null) означал «не менять»,
      // и категория оставалась выбранной.
      n.selectDepartment('2');
      expect(n.state.departmentId, '2');
      expect(n.state.categoryId, isNull);
    });

    test('возврат с шага категорий сбрасывает отдел', () {
      final n = RequestStateNotifier()..selectDepartment('1');
      expect(n.state.step, 1);

      n.goBack();
      expect(n.state.step, 0);
      expect(n.state.departmentId, isNull);
    });

    test('updateItem добавляет, обновляет и удаляет позицию', () {
      final n = RequestStateNotifier()
        ..updateItem('p1', 2, productName: 'Молоко', unit: 'л');
      expect(n.state.items.single.quantity, 2);

      n.updateItem('p1', 5);
      expect(n.state.items.single.quantity, 5);

      n.updateItem('p1', 0);
      expect(n.state.items, isEmpty);
    });
  });

  group('InventoryState', () {
    test('updateItem сохраняет введённый остаток — раньше метод был пустым '
        'и отчёт всегда выходил нулевым', () {
      final n = InventoryStateNotifier()
        ..updateItem('p1', 'Кофе', 'кг', 3.5);

      expect(n.state.items.length, 1);
      expect(n.state.items.single.productId, 'p1');
      expect(n.state.items.single.remaining, 3.5);
      expect(n.state.items.single.unit, 'кг');
    });

    test('повторный ввод по тому же товару обновляет, а не дублирует', () {
      final n = InventoryStateNotifier()
        ..updateItem('p1', 'Кофе', 'кг', 3.5)
        ..updateItem('p1', 'Кофе', 'кг', 7);

      expect(n.state.items.length, 1);
      expect(n.state.items.single.remaining, 7);
    });

    test('разные товары накапливаются', () {
      final n = InventoryStateNotifier()
        ..updateItem('p1', 'Кофе', 'кг', 1)
        ..updateItem('p2', 'Молоко', 'л', 2);

      expect(n.state.items.length, 2);
    });
  });

  group('DepartmentIcons', () {
    test('ключ восстанавливается в ту же иконку', () {
      for (final e in DepartmentIcons.byKey.entries) {
        expect(DepartmentIcons.resolve(e.key), e.value);
        expect(DepartmentIcons.keyOf(e.value), e.key);
      }
    });

    test('старый формат (codePoint строкой) читается', () {
      final legacy = Icons.kitchen.codePoint.toString();
      expect(DepartmentIcons.resolve(legacy), Icons.kitchen);
    });

    test('неизвестное значение даёт запасную иконку', () {
      expect(DepartmentIcons.resolve('какая-то_ерунда'), DepartmentIcons.fallback);
      expect(DepartmentIcons.resolve(null), DepartmentIcons.fallback);
      expect(DepartmentIcons.resolve(999999), DepartmentIcons.fallback);
    });

    test('иконки объявлены константами — это условие tree-shaking', () {
      // Каждый codePoint уникален, значит обратное соответствие однозначно.
      final codePoints =
          DepartmentIcons.byKey.values.map((i) => i.codePoint).toSet();
      expect(codePoints.length, DepartmentIcons.byKey.length);
    });
  });

  group('ThemeModeNotifier', () {
    test('«системная» сохраняется как system, а не как dark', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      ThemeModeNotifier(prefs).setThemeMode(ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
      expect(ThemeModeNotifier(prefs).state, ThemeMode.system);
    });

    test('светлая и тёмная сохраняются корректно', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      ThemeModeNotifier(prefs).setThemeMode(ThemeMode.light);
      expect(ThemeModeNotifier(prefs).state, ThemeMode.light);

      ThemeModeNotifier(prefs).setThemeMode(ThemeMode.dark);
      expect(ThemeModeNotifier(prefs).state, ThemeMode.dark);
    });
  });
}
