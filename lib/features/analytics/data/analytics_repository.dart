import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShiftRecord {
  final DateTime date;
  final double revenue;
  final double qr;
  final double card;
  final double cash;
  final double morningCash;
  final double eveningCash;
  final Map<String, int> writeOffs;

  ShiftRecord({
    required this.date,
    required this.revenue,
    required this.writeOffs,
    this.qr = 0,
    this.card = 0,
    this.cash = 0,
    this.morningCash = 0,
    this.eveningCash = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'revenue': revenue,
        'qr': qr,
        'card': card,
        'cash': cash,
        'morningCash': morningCash,
        'eveningCash': eveningCash,
        'writeOffs': writeOffs,
      };

  factory ShiftRecord.fromJson(Map<String, dynamic> json) => ShiftRecord(
        date: DateTime.parse(json['date'] as String),
        revenue: _toDouble(json['revenue']),
        qr: _toDouble(json['qr']),
        card: _toDouble(json['card']),
        cash: _toDouble(json['cash']),
        morningCash: _toDouble(json['morningCash']),
        eveningCash: _toDouble(json['eveningCash']),
        writeOffs: _toIntMap(json['writeOffs']),
      );

  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);

  /// Раньше здесь было `Map<String, int>.from(...)`, и одно дробное значение
  /// роняло разбор всего файла — вся аналитика молча обнулялась.
  static Map<String, int> _toIntMap(Object? v) {
    if (v is! Map) return <String, int>{};
    final out = <String, int>{};
    v.forEach((key, value) {
      final k = key?.toString();
      if (k == null) return;
      if (value is num) {
        out[k] = value.round();
      } else if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) out[k] = parsed.round();
      }
    });
    return out;
  }
}

/// Хранилище закрытых смен.
///
/// Как и история, раньше это был Provider с изменяемым списком: addShift()
/// не вызывал перестроение, и только что закрытая смена не появлялась
/// в аналитике до перезапуска приложения.
class AnalyticsRepository extends StateNotifier<List<ShiftRecord>> {
  final SharedPreferences _prefs;

  static const _key = 'shift_records';
  static const _schemaKey = 'shift_records_schema';
  static const _schemaVersion = 1;
  static const maxRecords = 1000;

  AnalyticsRepository(this._prefs) : super(const []) {
    _load();
  }

  void _load() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return;
    try {
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      state = data
          .map((e) => ShiftRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _prefs.setString('${_key}_corrupt', jsonString);
      _prefs.remove(_key);
      state = const [];
      debugPrint('AnalyticsRepository: не удалось прочитать смены: $e\n$st');
    }
  }

  void _save() {
    _prefs.setInt(_schemaKey, _schemaVersion);
    _prefs.setString(_key, jsonEncode(state.map((r) => r.toJson()).toList()));
  }

  void addShift(ShiftRecord record) {
    final next = [...state, record];
    state = next.length > maxRecords
        ? next.sublist(next.length - maxRecords)
        : next;
    _save();
  }

  /// Смены за последние [n] календарных дней, от старых к новым.
  ///
  /// Раньше отсечка бралась как `now - n дней` с учётом времени суток, из-за
  /// чего сегодняшняя смена могла не попасть в выборку.
  List<ShiftRecord> getLastNDays(int n) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: n - 1));
    return state.where((r) => !r.date.isBefore(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  ShiftRecord? getYesterdayShift() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final candidates = state
        .where((r) =>
            !r.date.isBefore(yesterdayStart) && r.date.isBefore(todayStart))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Изменение выручки последней смены к предыдущей, в процентах.
  double? getRevenueChangePercent() {
    if (state.length < 2) return null;
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted[0].revenue;
    final previous = sorted[1].revenue;
    if (previous == 0) return null;
    return ((latest - previous) / previous) * 100;
  }

  Map<String, int> getTopWriteOffs({int limit = 5}) {
    final totals = <String, int>{};
    for (final record in state) {
      record.writeOffs.forEach((name, qty) {
        totals[name] = (totals[name] ?? 0) + qty;
      });
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  void clear() {
    state = const [];
    _save();
  }
}

final analyticsRepositoryProvider =
    StateNotifierProvider<AnalyticsRepository, List<ShiftRecord>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AnalyticsRepository(prefs);
});
