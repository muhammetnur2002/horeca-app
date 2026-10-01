import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/core/money.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

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

int _toMinor(double v) => (Money.round(v) * 100).round();
double _fromMinor(int v) => v / 100;

/// Закрытые смены заведения. Хранятся в базе (суммы — в минорных
/// единицах), состояние — список от старых к новым.
class AnalyticsRepository extends StateNotifier<List<ShiftRecord>> {
  final OperationsDao _dao;
  final String _venueId;

  AnalyticsRepository(this._dao, this._venueId) : super(const []) {
    _ready = _load();
  }

  late final Future<void> _ready;

  /// Завершается, когда данные загружены из базы.
  Future<void> get ready => _ready;

  Future<void> _load() async {
    final shifts = await _dao.loadShifts(_venueId);
    final records = <ShiftRecord>[];
    for (final s in shifts) {
      final writeoffs = await _dao.loadWriteoffs(s.id);
      final map = <String, int>{};
      for (final w in writeoffs) {
        map[w.productName] = (map[w.productName] ?? 0) + w.quantity.round();
      }
      records.add(ShiftRecord(
        date: s.closedAt.toLocal(),
        revenue: _fromMinor(s.revenueMinor),
        qr: _fromMinor(s.qrMinor),
        card: _fromMinor(s.cardMinor),
        cash: _fromMinor(s.cashMinor),
        morningCash: _fromMinor(s.morningCashMinor),
        eveningCash: _fromMinor(s.eveningCashMinor),
        writeOffs: map,
      ));
    }
    if (!mounted) return;
    state = records;
  }

  /// Сохраняет закрытую смену. [shiftId] — защита от двойной записи:
  /// смена с тем же id повторно не сохраняется.
  void addShift(
    ShiftRecord record, {
    String? shiftId,
    List<String> staffNames = const [],
    double inkass = 0,
    Map<String, String> writeoffProductIds = const {},
    Map<String, String> writeoffUnits = const {},
  }) {
    state = [...state, record];
    _dao.addShift(
      venueId: _venueId,
      id: shiftId ?? Ids.newId(),
      closedAt: record.date,
      staffNames: staffNames,
      revenueMinor: _toMinor(record.revenue),
      qrMinor: _toMinor(record.qr),
      cardMinor: _toMinor(record.card),
      cashMinor: _toMinor(record.cash),
      morningCashMinor: _toMinor(record.morningCash),
      eveningCashMinor: _toMinor(record.eveningCash),
      inkassMinor: _toMinor(inkass),
      writeoffs: record.writeOffs.entries
          .map((e) => ShiftWriteoffInput(
                productId: writeoffProductIds[e.key],
                productName: e.key,
                quantity: e.value.toDouble(),
                unit: writeoffUnits[e.key] ?? 'шт',
              ))
          .toList(),
    );
  }

  List<ShiftRecord> getAll() => List.unmodifiable(state);

  List<ShiftRecord> getLastNDays(int n) {
    final cutoff = DateTime.now().subtract(Duration(days: n));
    return state.where((r) => r.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  ShiftRecord? getYesterdayShift() {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final todayStart = DateTime(now.year, now.month, now.day);
    final candidates = state.where((r) =>
        r.date.isAfter(yesterday) && r.date.isBefore(todayStart)).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.date.compareTo(a.date));
    return candidates.first;
  }

  double? getRevenueChangePercent() {
    final sorted = List<ShiftRecord>.from(state)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (sorted.length < 2) return null;
    final today = sorted[0].revenue;
    final yesterday = sorted[1].revenue;
    if (yesterday == 0) return null;
    return ((today - yesterday) / yesterday) * 100;
  }

  Map<String, int> getTopWriteOffs({int limit = 5}) {
    final Map<String, int> totals = {};
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
    _dao.clearShifts(_venueId);
  }
}

final analyticsRepositoryProvider =
    StateNotifierProvider<AnalyticsRepository, List<ShiftRecord>>((ref) {
  return AnalyticsRepository(
    ref.watch(operationsDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});
