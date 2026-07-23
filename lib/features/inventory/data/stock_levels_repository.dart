import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

class StockLevelsRepository extends StateNotifier<Map<String, double>> {
  final SharedPreferences _prefs;
  static const _key = 'current_stock_levels';

  StockLevelsRepository(this._prefs) : super({}) {
    _load();
  }

  void _load() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      state = data.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {}
  }

  void updateLevels(Map<String, double> levels) {
    state = {...state, ...levels};
    _prefs.setString(_key, jsonEncode(state));
  }

  double? getLevel(String productId) => state[productId];
}

final stockLevelsRepositoryProvider =
    StateNotifierProvider<StockLevelsRepository, Map<String, double>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StockLevelsRepository(prefs);
});