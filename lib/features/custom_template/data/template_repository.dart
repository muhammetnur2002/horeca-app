import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/custom_template/data/template_models.dart';

class TemplateRepository extends StateNotifier<CustomTemplate?> {
  final SharedPreferences _prefs;
  static const _key = 'custom_inventory_template';

  TemplateRepository(this._prefs) : super(null) {
    _load();
  }

  void _load() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return;
    try {
      state = CustomTemplate.fromJson(jsonDecode(jsonString));
    } catch (_) {
      state = null;
    }
  }

  void saveTemplate(CustomTemplate template) {
    state = template;
    _prefs.setString(_key, jsonEncode(template.toJson()));
  }

  void removeTemplate() {
    state = null;
    _prefs.remove(_key);
  }
}

final templateRepositoryProvider =
    StateNotifierProvider<TemplateRepository, CustomTemplate?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TemplateRepository(prefs);
});