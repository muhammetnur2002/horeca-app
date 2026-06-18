import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';

class HistoryRepository {
  final SharedPreferences _prefs;
  static const _historyKey = 'history_data';
  List<HistoryEntry> _entries = [];

  HistoryRepository(this._prefs) {
    _loadFromPrefs();
  }

  void _saveToPrefs() {
    final data = _entries.map((e) => {
      'id': e.id,
      'type': e.type == HistoryType.request ? 'request' : 'inventory',
      'title': e.title,
      'text': e.text,
      'createdAt': e.createdAt.toIso8601String(),
    }).toList();
    _prefs.setString(_historyKey, jsonEncode(data));
  }

  void _loadFromPrefs() {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      _entries = data.map((item) => HistoryEntry(
        id: item['id'] as String,
        type: item['type'] == 'request' ? HistoryType.request : HistoryType.inventory,
        title: item['title'] as String,
        text: item['text'] as String,
        createdAt: DateTime.parse(item['createdAt'] as String),
      )).toList();
    } catch (_) {
      _entries = [];
    }
  }

  List<HistoryEntry> getAll() => List.unmodifiable(_entries.reversed);

  void add(HistoryEntry entry) {
    _entries.add(entry);
    _saveToPrefs();
  }

  void clear() {
    _entries.clear();
    _saveToPrefs();
  }

  void clearByType(HistoryType type) {
    _entries.removeWhere((entry) => entry.type == type);
    _saveToPrefs();
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryRepository(prefs);
});

final historyEntriesProvider = Provider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).getAll();
});