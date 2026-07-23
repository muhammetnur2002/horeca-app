import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

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
  revenue: (json['revenue'] as num).toDouble(),
  qr: (json['qr'] as num?)?.toDouble() ?? 0,
  card: (json['card'] as num?)?.toDouble() ?? 0,
  cash: (json['cash'] as num?)?.toDouble() ?? 0,
  morningCash: (json['morningCash'] as num?)?.toDouble() ?? 0,
  eveningCash: (json['eveningCash'] as num?)?.toDouble() ?? 0,
  writeOffs: Map<String, int>.from(json['writeOffs'] as Map),
);
}

class AnalyticsRepository {
  final SharedPreferences _prefs;
  static const _key = 'shift_records';
  List<ShiftRecord> _records = [];

  AnalyticsRepository(this._prefs) {
    _load();
  }

  void _load() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      _records = data.map((e) => ShiftRecord.fromJson(e)).toList();
    } catch (_) {
      _records = [];
    }
  }

  void _save() {
    final data = _records.map((r) => r.toJson()).toList();
    _prefs.setString(_key, jsonEncode(data));
  }

  void addShift(ShiftRecord record) {
    _records.add(record);
    _save();
  }

  List<ShiftRecord> getAll() => List.unmodifiable(_records);

  List<ShiftRecord> getLastNDays(int n) {
    final cutoff = DateTime.now().subtract(Duration(days: n));
    return _records.where((r) => r.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  ShiftRecord? getYesterdayShift() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final todayStart = DateTime(now.year, now.month, now.day);
    final candidates = _records.where((r) =>
        r.date.isAfter(yesterday) && r.date.isBefore(todayStart)).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.date.compareTo(a.date));
    return candidates.first;
  }
  double? getRevenueChangePercent() {
    final sorted = List<ShiftRecord>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.length < 2) return null;
    final today = sorted[0].revenue;
    final yesterday = sorted[1].revenue;
    if (yesterday == 0) return null;
    return ((today - yesterday) / yesterday) * 100;
  }

  Map<String, int> getTopWriteOffs({int limit = 5}) {
    final Map<String, int> totals = {};
    for (final record in _records) {
      record.writeOffs.forEach((name, qty) {
        totals[name] = (totals[name] ?? 0) + qty;
      });
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  void clear() {
    _records.clear();
    _save();
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AnalyticsRepository(prefs);
});


