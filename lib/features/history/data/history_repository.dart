import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';

/// Хранит историю заявок и инвентаризаций.
///
/// Это StateNotifier, а не обычный Provider: экран истории подписывается на
/// состояние, поэтому новые записи и очистка сразу видны без перезапуска.
/// Состояние отсортировано от новых к старым.
class HistoryRepository extends StateNotifier<List<HistoryEntry>> {
  final SharedPreferences _prefs;
  static const _historyKey = 'history_data';

  HistoryRepository(this._prefs) : super(const []) {
    _loadFromPrefs();
  }

  void _saveToPrefs() {
    final data = state
        .map((e) => {
              'id': e.id,
              'type': e.type == HistoryType.request ? 'request' : 'inventory',
              'title': e.title,
              'text': e.text,
              'createdAt': e.createdAt.toIso8601String(),
            })
        .toList();
    _prefs.setString(_historyKey, jsonEncode(data));
  }

  void _loadFromPrefs() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      state = _sorted(data
          .map((item) => HistoryEntry(
                id: item['id'] as String,
                type: item['type'] == 'request'
                    ? HistoryType.request
                    : HistoryType.inventory,
                title: item['title'] as String,
                text: item['text'] as String,
                createdAt: DateTime.parse(item['createdAt'] as String),
              ))
          .toList());
    } catch (_) {
      state = const [];
    }
  }

  static List<HistoryEntry> _sorted(List<HistoryEntry> entries) =>
      entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<HistoryEntry> getAll() => List.unmodifiable(state);

  void add(HistoryEntry entry) {
    state = _sorted([...state, entry]);
    _saveToPrefs();
  }

  void clear() {
    state = const [];
    _saveToPrefs();
  }

  void clearByType(HistoryType type) {
    state = state.where((entry) => entry.type != type).toList();
    _saveToPrefs();
  }
}

final historyRepositoryProvider =
    StateNotifierProvider<HistoryRepository, List<HistoryEntry>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryRepository(prefs);
});

/// Записи истории, от новых к старым.
final historyEntriesProvider = Provider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider);
});
