import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/app/backdrop.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be initialized in main');
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Выбранная тема оформления (одна из 5 палитр). Хранится в prefs и сразу
/// применяется к AppColors, чтобы все экраны брали цвета новой темы.
final paletteProvider =
    StateNotifierProvider<PaletteNotifier, AkylPalette>((ref) {
  return PaletteNotifier(ref.read(sharedPreferencesProvider));
});

class PaletteNotifier extends StateNotifier<AkylPalette> {
  static const _key = 'app_palette';
  final SharedPreferences _prefs;
  PaletteNotifier(this._prefs)
      : super(AkylPalette.fromKey(_prefs.getString(_key))) {
    AppColors.applyPalette(state);
  }

  Future<void> setPalette(AkylPalette p) async {
    // Сначала рисуем фон новой темы, затем переключаем — без мигания.
    await AkylBackdrop.prepare(p);
    AppColors.applyPalette(p);
    state = p;
    _prefs.setString(_key, p.key);
    // Часть виджетов не зависит от Theme и сама не перестроится — после
    // кадра с новой темой помечаем всё дерево на перерисовку (как при
    // hot reload), чтобы цвета обновились везде без перезапуска.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => WidgetsBinding.instance.reassembleApplication());
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    final saved = _prefs.getString('theme_mode');
    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system; // по умолчанию — системная
    }
  }
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString('theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
