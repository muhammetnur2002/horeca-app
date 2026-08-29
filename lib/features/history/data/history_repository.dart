import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Репозиторий истории заявок и инвентаризаций.
///
/// Раньше это был обычный Provider с изменяемым списком внутри: add() менял
/// поле, но Riverpod об этом не знал, и новые записи не появлялись на экране
/// до перезапуска приложения. Теперь список — это состояние StateNotifier.
class HistoryRepository extends StateNotifier<List<HistoryEntry>> {
  final SharedPreferences _prefs;

  static const _historyKey = 'history_data';
  static const _schemaKey = 'history_schema';
  static const _schemaVersion = 1;

  /// Верхняя граница журнала: SharedPreferences читается целиком при старте,
  /// поэтому неограниченный рост заметно замедлял запуск.
  static const maxEntries = 500;

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
    _prefs.setInt(_schemaKey, _schemaVersion);
    _prefs.setString(_historyKey, jsonEncode(data));
  }

  void _loadFromPrefs() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return;
    try {
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      state = data
          .map((item) => HistoryEntry(
                id: item['id'] as String,
                type: item['type'] == 'request'
                    ? HistoryType.request
                    : HistoryType.inventory,
                title: item['title'] as String,
                text: item['text'] as String,
                createdAt: DateTime.parse(item['createdAt'] as String),
              ))
          .toList();
    } catch (e, st) {
      // Раньше здесь стоял `catch (_) { _entries = []; }` — журнал молча
      // обнулялся. Теперь повреждённые данные сохраняются в отдельный ключ,
      // чтобы их можно было разобрать, а не потерять безвозвратно.
      _prefs.setString('${_historyKey}_corrupt', jsonString);
      _prefs.remove(_historyKey);
      state = const [];
      debugPrint('HistoryRepository: не удалось прочитать историю: $e\n$st');
    }
  }

  /// Записи от новых к старым — в таком порядке их показывает экран истории.
  List<HistoryEntry> get newestFirst => state.reversed.toList(growable: false);

  void add(HistoryEntry entry) {
    final next = [...state, entry];
    state = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
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

/// Готовый к отображению список — новые записи сверху.
final historyEntriesProvider = Provider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).reversed.toList(growable: false);
});
