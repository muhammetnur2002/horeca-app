import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';
import 'package:horeca_app/features/custom_template/data/template_models.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

class TemplateRepository extends StateNotifier<CustomTemplate?> {
  final SharedPreferences _prefs;
  final String _key;
  final void Function()? _onChanged;

  TemplateRepository(this._prefs, String venueCode, {void Function()? onChanged})
      : _key = 'custom_inventory_template${venueKeySuffix(venueCode)}',
        _onChanged = onChanged,
        super(null) {
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
    _onChanged?.call();
  }

  void removeTemplate() {
    state = null;
    _prefs.remove(_key);
    _onChanged?.call();
  }
}

final templateRepositoryProvider =
    StateNotifierProvider<TemplateRepository, CustomTemplate?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final venueCode = ref.watch(venueRepositoryProvider).activeVenueCode;
  return TemplateRepository(prefs, venueCode,
      onChanged: () => ref.read(cloudAutoSyncProvider).scheduleSync());
});
