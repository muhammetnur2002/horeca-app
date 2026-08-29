import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  HistoryEntry entry(String id, {HistoryType type = HistoryType.request}) =>
      HistoryEntry(
        id: id,
        type: type,
        title: 'Заявка $id',
        text: 'тело',
        createdAt: DateTime(2026, 1, 1).add(Duration(minutes: int.parse(id))),
      );

  group('HistoryRepository', () {
    test('add меняет состояние — раньше запись была видна только после '
        'перезапуска', () async {
      final repo = HistoryRepository(await prefsWith({}));
      expect(repo.state, isEmpty);

      repo.add(entry('1'));
      expect(repo.state.length, 1);

      repo.add(entry('2'));
      expect(repo.state.length, 2);
    });

    test('записи переживают пересоздание репозитория', () async {
      final prefs = await prefsWith({});
      HistoryRepository(prefs).add(entry('1'));

      expect(HistoryRepository(prefs).state.length, 1);
    });

    test('журнал не растёт бесконечно', () async {
      final repo = HistoryRepository(await prefsWith({}));
      for (var i = 0; i < HistoryRepository.maxEntries + 20; i++) {
        repo.add(entry('$i'));
      }
      expect(repo.state.length, HistoryRepository.maxEntries);
      // Обрезаются самые старые.
      expect(repo.state.first.id, '20');
    });

    test('clearByType удаляет только свой тип', () async {
      final repo = HistoryRepository(await prefsWith({}))
        ..add(entry('1'))
        ..add(entry('2', type: HistoryType.inventory));

      repo.clearByType(HistoryType.request);
      expect(repo.state.length, 1);
      expect(repo.state.single.type, HistoryType.inventory);
    });

    test('повреждённые данные сохраняются, а не пропадают молча', () async {
      final prefs = await prefsWith({'history_data': '{не json'});
      final repo = HistoryRepository(prefs);

      expect(repo.state, isEmpty);
      expect(prefs.getString('history_data_corrupt'), '{не json');
    });
  });

  group('AnalyticsRepository', () {
    ShiftRecord shift(DateTime date, double revenue,
            [Map<String, int> writeOffs = const {}]) =>
        ShiftRecord(date: date, revenue: revenue, writeOffs: writeOffs);

    test('addShift меняет состояние', () async {
      final repo = AnalyticsRepository(await prefsWith({}));
      repo.addShift(shift(DateTime.now(), 1000));
      expect(repo.state.length, 1);
    });

    test('дробное количество списаний не роняет разбор всей аналитики',
        () async {
      // Раньше Map<String,int>.from падал на дробном значении, и в catch(_)
      // обнулялся весь список смен.
      final raw = jsonEncode([
        {
          'date': DateTime(2026, 1, 1).toIso8601String(),
          'revenue': 500,
          'writeOffs': {'Молоко': 2.6, 'Кофе': 3},
        }
      ]);
      final repo = AnalyticsRepository(await prefsWith({'shift_records': raw}));

      expect(repo.state.length, 1);
      expect(repo.state.single.writeOffs['Молоко'], 3);
      expect(repo.state.single.writeOffs['Кофе'], 3);
    });

    test('getLastNDays включает сегодняшнюю смену', () async {
      final repo = AnalyticsRepository(await prefsWith({}));
      final now = DateTime.now();
      repo.addShift(shift(now, 100));
      repo.addShift(shift(now.subtract(const Duration(days: 2)), 200));
      repo.addShift(shift(now.subtract(const Duration(days: 30)), 300));

      final week = repo.getLastNDays(7);
      expect(week.length, 2);
      expect(week.first.revenue, 200, reason: 'отсортировано от старых к новым');
    });

    test('getRevenueChangePercent сравнивает две последние смены', () async {
      final repo = AnalyticsRepository(await prefsWith({}));
      repo.addShift(shift(DateTime(2026, 1, 1), 100));
      repo.addShift(shift(DateTime(2026, 1, 2), 150));

      expect(repo.getRevenueChangePercent(), 50);
    });

    test('без второй смены изменение не считается', () async {
      final repo = AnalyticsRepository(await prefsWith({}));
      repo.addShift(shift(DateTime(2026, 1, 1), 100));
      expect(repo.getRevenueChangePercent(), isNull);
    });

    test('getTopWriteOffs суммирует по всем сменам', () async {
      final repo = AnalyticsRepository(await prefsWith({}));
      repo.addShift(shift(DateTime(2026, 1, 1), 0, {'Молоко': 2, 'Кофе': 1}));
      repo.addShift(shift(DateTime(2026, 1, 2), 0, {'Молоко': 3}));

      final top = repo.getTopWriteOffs(limit: 2);
      expect(top['Молоко'], 5);
      expect(top.keys.first, 'Молоко');
    });
  });
}
