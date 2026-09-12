import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

ProviderContainer containerWith(SharedPreferences prefs) {
  final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier', () {
    test('сохраняет системную тему как system, а не как dark', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      c.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
      expect(c.read(themeModeProvider), ThemeMode.system);
    });

    test('восстанавливает каждый из трёх режимов', () async {
      for (final entry in {
        'light': ThemeMode.light,
        'dark': ThemeMode.dark,
        'system': ThemeMode.system,
      }.entries) {
        final prefs = await freshPrefs({'theme_mode': entry.key});
        expect(containerWith(prefs).read(themeModeProvider), entry.value);
      }
    });
  });

  group('SettingsRepository', () {
    test('updateProduct сохраняет минимальный остаток', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      final repo = c.read(settingsRepositoryProvider.notifier);
      final id = c.read(settingsRepositoryProvider).products.first.id;

      repo.setProductMinStock(id, 7);
      repo.updateProduct(id, 'Томаты черри', 'кг');

      final p =
          c.read(settingsRepositoryProvider).products.firstWhere((p) => p.id == id);
      expect(p.name, 'Томаты черри');
      expect(p.minStock, 7, reason: 'порог не должен теряться при переименовании');
    });

    test('resetAll очищает всё, что обещает диалог', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      c.read(settingsRepositoryProvider.notifier).resetAll();

      final s = c.read(settingsRepositoryProvider);
      expect(s.departments, isEmpty);
      expect(s.categories, isEmpty);
      expect(s.products, isEmpty);
      expect(s.staff, isEmpty);
      expect(s.establishmentName, isEmpty);
      expect(s.logoPath, isNull);
    });

    test('массовое добавление даёт уникальные id', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      final repo = c.read(settingsRepositoryProvider.notifier);
      final catId = c.read(settingsRepositoryProvider).categories.first.id;

      repo.bulkAddProducts(['Соль', 'Перец', 'Соль'], 'кг', catId);
      final added = c
          .read(settingsRepositoryProvider)
          .products
          .where((p) => p.categoryId == catId)
          .map((p) => p.id)
          .toList();
      expect(added.toSet().length, added.length);
    });

    test('удаление отдела уносит его категории и товары', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      final repo = c.read(settingsRepositoryProvider.notifier);
      repo.deleteDepartment('1');

      final s = c.read(settingsRepositoryProvider);
      expect(s.categories.where((x) => x.departmentId == '1'), isEmpty);
      expect(s.products.any((p) => p.categoryId == '1'), isFalse);
      // Отделы, не связанные с удалённым, остаются нетронутыми.
      expect(s.categories.any((x) => x.departmentId == '2'), isTrue);
    });

    test('иконки отделов переживают перезапуск', () async {
      final prefs = await freshPrefs();
      containerWith(prefs)
          .read(settingsRepositoryProvider.notifier)
          .addDepartment('Кондитерская', Icons.icecream);

      final reloaded = containerWith(prefs).read(settingsRepositoryProvider);
      final d = reloaded.departments.firstWhere((d) => d.name == 'Кондитерская');
      expect(d.icon, Icons.icecream);
      final kitchen = reloaded.departments.firstWhere((d) => d.id == '1');
      expect(kitchen.icon, Icons.kitchen);
    });
  });

  group('HistoryRepository', () {
    test('новая запись сразу видна подписчикам и идёт первой', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      expect(c.read(historyEntriesProvider), isEmpty);

      final repo = c.read(historyRepositoryProvider.notifier);
      repo.add(HistoryEntry(
        id: '1', type: HistoryType.request, title: 'Старая', text: 'a',
        createdAt: DateTime(2026, 1, 1),
      ));
      repo.add(HistoryEntry(
        id: '2', type: HistoryType.request, title: 'Новая', text: 'b',
        createdAt: DateTime(2026, 6, 1),
      ));

      final entries = c.read(historyEntriesProvider);
      expect(entries.length, 2);
      expect(entries.first.title, 'Новая', reason: 'новые записи сверху');
    });

    test('clearByType удаляет только свой тип', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      final repo = c.read(historyRepositoryProvider.notifier);
      repo.add(HistoryEntry(
          id: '1', type: HistoryType.request, title: 'з', text: '',
          createdAt: DateTime(2026, 1, 1)));
      repo.add(HistoryEntry(
          id: '2', type: HistoryType.inventory, title: 'и', text: '',
          createdAt: DateTime(2026, 1, 2)));

      repo.clearByType(HistoryType.request);
      final left = c.read(historyEntriesProvider);
      expect(left.length, 1);
      expect(left.single.type, HistoryType.inventory);
    });

    test('история переживает перезапуск', () async {
      final prefs = await freshPrefs();
      containerWith(prefs).read(historyRepositoryProvider.notifier).add(
            HistoryEntry(
                id: '1', type: HistoryType.request, title: 'Заявка',
                text: 'текст', createdAt: DateTime(2026, 3, 3)),
          );
      expect(containerWith(prefs).read(historyEntriesProvider).single.title,
          'Заявка');
    });
  });

  group('RequestStateNotifier', () {
    test('шаг назад действительно сбрасывает отдел и категорию', () {
      final n = RequestStateNotifier();
      n.selectDepartment('1');
      n.selectCategory('2');
      expect(n.state.step, 2);

      n.goBack();
      expect(n.state.step, 1);
      expect(n.state.categoryId, isNull, reason: 'категория должна очиститься');

      n.goBack();
      expect(n.state.step, 0);
      expect(n.state.departmentId, isNull, reason: 'отдел должен очиститься');
    });

    test('выбор другого отдела не тянет за собой старую категорию', () {
      final n = RequestStateNotifier();
      n.selectDepartment('1');
      n.selectCategory('5');
      n.goBack();
      n.goBack();
      n.selectDepartment('2');
      expect(n.state.categoryId, isNull);
    });

    test('количество 0 убирает позицию, дробное сохраняется', () {
      final n = RequestStateNotifier();
      n.updateItem('p1', 1.5, productName: 'Сыр', unit: 'кг');
      expect(n.state.items.single.quantity, 1.5);
      n.updateItem('p1', 0);
      expect(n.state.items, isEmpty);
    });
  });

  group('InventoryStateNotifier', () {
    test('updateItem действительно записывает остаток', () {
      final n = InventoryStateNotifier();
      n.selectDepartment('1', ['1']);
      n.confirmCategories();
      n.updateItem('p1', 'Томаты', 'кг', 3);
      expect(n.state.items.single.remaining, 3);

      // Повторный ввод обновляет ту же позицию, а не добавляет вторую.
      n.updateItem('p1', 'Томаты', 'кг', 4.5);
      expect(n.state.items.length, 1);
      expect(n.state.items.single.remaining, 4.5);
    });

    test('нулевой остаток остаётся в отчёте, отрицательный обнуляется', () {
      final n = InventoryStateNotifier();
      n.updateItem('p1', 'Томаты', 'кг', 0);
      expect(n.state.items.single.remaining, 0);
      n.updateItem('p1', 'Томаты', 'кг', -5);
      expect(n.state.items.single.remaining, 0);
    });

    test('назад со списка ведёт к категориям, а не к полному сбросу', () {
      final n = InventoryStateNotifier();
      n.selectDepartment('2', ['4', '5']);
      n.confirmCategories();
      n.backToCategories();
      expect(n.state.step, 1);
      expect(n.state.departmentId, '2');
      expect(n.state.selectedCategoryIds, ['4', '5']);
    });
  });

  group('AuthRepository', () {
    test('без PIN-кодов пользователь считается администратором', () async {
      final prefs = await freshPrefs();
      expect(containerWith(prefs).read(authRepositoryProvider).isAdmin, isTrue);
    });

    test('сотрудник не администратор, выход снимает вход', () async {
      final prefs = await freshPrefs();
      final c = containerWith(prefs);
      final repo = c.read(authRepositoryProvider.notifier);
      repo.setAdminPin('1111');
      repo.setStaffPin('2222');
      repo.setPinsEnabled(true);

      expect(repo.checkPin('2222'), UserRole.staff);
      repo.login(UserRole.staff);
      expect(c.read(authRepositoryProvider).isAdmin, isFalse);

      repo.logout();
      final s = c.read(authRepositoryProvider);
      expect(s.isLoggedIn, isFalse);
      expect(s.pinsEnabled, isTrue, reason: 'выход не отключает защиту');
    });

    test('пустой PIN не открывает доступ', () async {
      final prefs = await freshPrefs();
      final repo = containerWith(prefs).read(authRepositoryProvider.notifier);
      repo.setPinsEnabled(true);
      expect(repo.checkPin(''), isNull);
      expect(repo.checkPin('0000'), isNull);
    });
  });

  group('AnalyticsRepository', () {
    test('смены сохраняются и переживают перезапуск', () async {
      final prefs = await freshPrefs();
      containerWith(prefs).read(analyticsRepositoryProvider).addShift(
            ShiftRecord(
                date: DateTime(2026, 5, 1), revenue: 1000, writeOffs: {'Торт': 2}),
          );
      final repo = containerWith(prefs).read(analyticsRepositoryProvider);
      expect(repo.getAll().single.revenue, 1000);
      expect(repo.getTopWriteOffs()['Торт'], 2);
    });
  });
}
