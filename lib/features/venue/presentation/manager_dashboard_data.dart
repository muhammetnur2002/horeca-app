/// Загрузка и агрегация данных для дашборда управляющего — читает Firestore
/// по каждому заведению аккаунта и считает сегодняшнюю/вчерашнюю выручку,
/// списания и сравнение с прошлой неделей. Вынесено из
/// manager_dashboard_screen.dart, чтобы не раздувать его.
library;

import 'dart:convert';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_models.dart';

Future<List<VenueSnapshot>> fetchVenueSnapshots(String uid) async {
  final venues = await CloudSyncService.pullVenueRegistry(uid) ?? const <Venue>[];
  final results = <VenueSnapshot>[];
  for (final v in venues) {
    final data = await CloudSyncService.fetchVenueDataRaw(uid, v.code);
    if (data == null) {
      results.add(VenueSnapshot(
        venue: v,
        todayRevenue: 0,
        yesterdayRevenue: 0,
        shiftsToday: 0,
        writeOffsTotal: const {},
        error: 'Нет данных в облаке для этого заведения',
      ));
      continue;
    }
    final recordsRaw = data['shift_records'];
    List<ShiftRecord> records = [];
    if (recordsRaw is String) {
      try {
        final list = jsonDecode(recordsRaw) as List;
        records = list.map((e) => ShiftRecord.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        // повреждённые данные конкретного заведения не должны ронять весь дашборд
      }
    }
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final todayRecords = records
        .where((r) => !r.date.isBefore(todayStart))
        .toList();
    final yesterdayRecords = records
        .where((r) => !r.date.isBefore(yesterdayStart) && r.date.isBefore(todayStart))
        .toList();
    final todayRevenue = todayRecords.fold<double>(0, (s, r) => s + r.revenue);
    final yesterdayRevenue = yesterdayRecords.fold<double>(0, (s, r) => s + r.revenue);
    final Map<String, int> writeOffsTotal = {};
    for (final r in records) {
      r.writeOffs.forEach((name, qty) {
        writeOffsTotal[name] = (writeOffsTotal[name] ?? 0) + qty;
      });
    }

    // Последние 7 дней (включая сегодня) и предыдущие 7 — база для
    // текстовых инсайтов ("выручка +12% к прошлой неделе" и т.п.).
    final weekStart = todayStart.subtract(const Duration(days: 6));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final weekRecords = records.where((r) => !r.date.isBefore(weekStart)).toList();
    final prevWeekRecords = records
        .where((r) => !r.date.isBefore(prevWeekStart) && r.date.isBefore(weekStart))
        .toList();
    final weekRevenue = weekRecords.fold<double>(0, (s, r) => s + r.revenue);
    final prevWeekRevenue = prevWeekRecords.fold<double>(0, (s, r) => s + r.revenue);
    final Map<String, int> weekWriteOffs = {};
    for (final r in weekRecords) {
      r.writeOffs.forEach((name, qty) {
        weekWriteOffs[name] = (weekWriteOffs[name] ?? 0) + qty;
      });
    }
    final Map<String, int> prevWeekWriteOffs = {};
    for (final r in prevWeekRecords) {
      r.writeOffs.forEach((name, qty) {
        prevWeekWriteOffs[name] = (prevWeekWriteOffs[name] ?? 0) + qty;
      });
    }

    results.add(VenueSnapshot(
      venue: v,
      todayRevenue: todayRevenue,
      yesterdayRevenue: yesterdayRevenue,
      shiftsToday: todayRecords.length,
      writeOffsTotal: writeOffsTotal,
      weekRevenue: weekRevenue,
      prevWeekRevenue: prevWeekRevenue,
      weekWriteOffs: weekWriteOffs,
      prevWeekWriteOffs: prevWeekWriteOffs,
    ));
  }
  return results;
}
