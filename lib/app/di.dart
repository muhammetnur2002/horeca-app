import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be initialized in main');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

const themeModePrefsKey = 'theme_mode';

/// Три режима хранятся разными строками. Раньше всё, кроме светлой темы,
/// записывалось как `dark`, и «Авто» после перезапуска становилось тёмной.
String encodeThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

ThemeMode decodeThemeMode(String? saved) {
  switch (saved) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    state = decodeThemeMode(_prefs.getString(themeModePrefsKey));
  }
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(themeModePrefsKey, encodeThemeMode(mode));
  }
}
