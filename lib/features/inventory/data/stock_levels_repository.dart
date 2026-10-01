import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

class StockLevelsRepository extends StateNotifier<Map<String, double>> {
  final SharedPreferences _prefs;
  // Отдельно для каждого заведения: id товаров ("1".."10" у стартового
  // набора) совпадают в разных заведениях, и общий ключ смешивал их остатки.
  final String _key;

  StockLevelsRepository(this._prefs, String venueCode)
      : _key = 'current_stock_levels${venueKeySuffix(venueCode)}',
        super({}) {
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
  final venueCode = ref.watch(venueRepositoryProvider).activeVenueCode;
  return StockLevelsRepository(prefs, venueCode);
});
