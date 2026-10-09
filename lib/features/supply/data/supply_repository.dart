import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';
import 'package:horeca_app/features/supply/domain/ocr_quota.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';
import 'package:horeca_app/features/supply/domain/supply_models.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

class SupplySnapshot {
  final List<SupplyRequest> requests;
  final List<GoodsReceipt> receipts;
  final List<StockMove> moves;
  final OcrQuota quota;

  const SupplySnapshot({
    this.requests = const [],
    this.receipts = const [],
    this.moves = const [],
    this.quota = const OcrQuota(day: '', used: 0),
  });
}

class SupplyRepository extends StateNotifier<SupplySnapshot> {
  final SharedPreferences _prefs;
  final String _suffix;
  final void Function()? _onChanged;
  static const _secure = FlutterSecureStorage();
  static const gigachatKeyName = 'gigachat_authorization_key';

  SupplyRepository(this._prefs, String venueCode, {void Function()? onChanged})
      : _suffix = venueKeySuffix(venueCode),
        _onChanged = onChanged,
        super(const SupplySnapshot()) {
    _load();
  }

  String get _requestsKey => 'supply_requests$_suffix';
  String get _receiptsKey => 'goods_receipts$_suffix';
  String get _movesKey => 'stock_moves$_suffix';
  String get _quotaKey => 'ocr_quota$_suffix';

  void _load() {
    state = SupplySnapshot(
      requests: _readList(_requestsKey, SupplyRequest.fromJson),
      receipts: _readList(_receiptsKey, GoodsReceipt.fromJson),
      moves: _readList(_movesKey, StockMove.fromJson),
      quota: OcrQuota.fromJson(_readMap(_quotaKey), DateTime.now()),
    );
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) decode) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return [
        for (final item in data)
          if (item is Map) decode(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic>? _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  void _write(String key, Object value) {
    _prefs.setString(key, jsonEncode(value));
    _onChanged?.call();
  }

  void upsertRequest(SupplyRequest request) {
    final next = [...state.requests.where((r) => r.id != request.id), request];
    state = SupplySnapshot(
      requests: next,
      receipts: state.receipts,
      moves: state.moves,
      quota: state.quota,
    );
    _write(_requestsKey, next.map((e) => e.toJson()).toList());
  }

  void saveReceipt(GoodsReceipt receipt) {
    final next = [...state.receipts.where((r) => r.id != receipt.id), receipt];
    final moves = [...state.moves];
    for (final line in receipt.lines) {
      if (line.receivedQty <= 0) continue;
      final productKey = line.productId.isNotEmpty
          ? line.productId
          : nameProductKey(line.name);
      moves.add(StockMove(
        id: '${receipt.id}:$productKey:${line.name}',
        at: receipt.createdAt,
        productKey: productKey,
        name: line.name,
        unit: line.unit,
        kind: StockMoveKind.receipt,
        qty: line.receivedQty,
      ));
    }
    state = SupplySnapshot(
      requests: state.requests,
      receipts: next,
      moves: moves,
      quota: state.quota,
    );
    _write(_receiptsKey, next.map((e) => e.toJson()).toList());
    _write(_movesKey, moves.map((e) => e.toJson()).toList());
  }

  void recordCounts({
    required DateTime at,
    required List<StockMove> counts,
  }) {
    if (counts.isEmpty) return;
    final moves = [
      ...state.moves,
      for (final count in counts)
        if (count.qty >= 0)
          StockMove(
            id: count.id,
            at: at,
            productKey: count.productKey,
            name: count.name,
            unit: count.unit,
            kind: StockMoveKind.count,
            qty: count.qty,
          ),
    ];
    _setMoves(moves);
  }

  void recordWriteOffs({
    required DateTime at,
    required String batchId,
    required Map<String, double> quantities,
    String Function(String name)? productKeyFor,
    String Function(String name)? unitFor,
  }) {
    if (quantities.isEmpty) return;
    final moves = [...state.moves];
    quantities.forEach((name, qty) {
      if (qty <= 0 || name.trim().isEmpty) return;
      final key = productKeyFor?.call(name) ?? nameProductKey(name);
      final unit = unitFor?.call(name).trim() ?? '';
      moves.add(StockMove(
        id: '$batchId:$key',
        at: at,
        productKey: key,
        name: name,
        unit: unit.isEmpty ? 'шт' : unit,
        kind: StockMoveKind.writeOff,
        qty: qty,
      ));
    });
    _setMoves(moves);
  }

  /// Расход лежит по дням. Повторный запрос заменяет только дни своего
  /// срока: короткий запрос не стирает расход длинного за другие дни.
  void replaceConsumption({
    required DateTime from,
    required DateTime to,
    required List<StockMove> consumption,
  }) {
    final firstDay = DateTime(from.year, from.month, from.day);
    final afterLastDay = DateTime(to.year, to.month, to.day + 1);
    final kept = state.moves.where((m) {
      if (m.kind != StockMoveKind.consumption) return true;
      return m.at.isBefore(firstDay) || !m.at.isBefore(afterLastDay);
    });
    _setMoves([...kept, ...consumption]);
  }

  void _setMoves(List<StockMove> moves) {
    state = SupplySnapshot(
      requests: state.requests,
      receipts: state.receipts,
      moves: moves,
      quota: state.quota,
    );
    _write(_movesKey, moves.map((e) => e.toJson()).toList());
  }

  /// false — лимит на сегодня уже выбран.
  bool consumeRecognition() {
    final today = OcrQuota.fromJson(state.quota.toJson(), DateTime.now());
    if (!today.canRecognize) {
      state = SupplySnapshot(
        requests: state.requests,
        receipts: state.receipts,
        moves: state.moves,
        quota: today,
      );
      return false;
    }
    final next = today.consume();
    state = SupplySnapshot(
      requests: state.requests,
      receipts: state.receipts,
      moves: state.moves,
      quota: next,
    );
    _write(_quotaKey, next.toJson());
    return true;
  }

  static Future<String?> readGigaChatKey() async {
    try {
      final value = await _secure.read(key: gigachatKeyName);
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGigaChatKey(String raw) async {
    var value = raw.trim();
    if (value.toLowerCase().startsWith('basic ')) {
      value = value.substring(6).trim();
    }
    if (value.isEmpty) {
      await _secure.delete(key: gigachatKeyName);
      return;
    }
    await _secure.write(key: gigachatKeyName, value: value);
  }
}

final supplyRepositoryProvider =
    StateNotifierProvider<SupplyRepository, SupplySnapshot>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final venueCode = ref.watch(venueRepositoryProvider).activeVenueCode;
  return SupplyRepository(
    prefs,
    venueCode,
    onChanged: () => ref.read(cloudAutoSyncProvider).scheduleSync(),
  );
});

/// Одна заявка на экране генерации обновляется, а не плодит копии.
final openSupplyRequestIdProvider = StateProvider<String?>((ref) => null);
