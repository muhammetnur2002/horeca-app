/// Цвета приложения и светлая/тёмная темы Material. Вынесены из app.dart,
/// чтобы не раздувать его; app.dart реэкспортирует этот файл, так что
/// `import '.../app/app.dart'` по-прежнему даёт доступ к AppColors во всех
/// остальных файлах проекта без изменения их импортов.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Цветовые константы (меняй только здесь) ───────────────────────────────
class AppColors {
  // Фирменная палитра — строго три цвета. Остальные оттенки ниже — это
  // они же, смешанные друг с другом (поверхности, карточки, подписи).
  static const black        = Color(0xFF0B0B0C);
  static const cream        = Color(0xFFF2F0EC);
  static const orange       = Color(0xFFFF6A00);

  // Тёмная тема: чёрный с 6 / 10 / 14 % кремового.
  static const darkBg       = black;
  static const darkSurface  = Color(0xFF191919);
  static const darkCard     = Color(0xFF222222);
  static const darkCard2    = Color(0xFF2B2B2B);

  // Светлая тема: кремовый, поверхности — кремовый с 4 % чёрного.
  static const lightBg      = cream;
  static const lightSurface = Color(0xFFE9E7E3);
  static const lightCard    = cream;

  static const orangeLight  = orange;
  static const green        = Color(0xFF639922);
  static const greenLight   = Color(0xFF97C459);

  /// Подписи: кремовый на 55 % поверх чёрного.
  static const muted        = Color(0xFF8A8987);

  /// Те же смыслы, что и заливка в Excel: много / мало / плохо.
  static const markHigh     = Color(0xFF3D8B40);
  static const markLow      = Color(0xFFE0A100);
  static const markBad      = Color(0xFFD64545);
}

class AppMetrics {
  static const screen = 20.0;
  static const gap = 12.0;
  static const radius = 18.0;
  static const motion = Duration(milliseconds: 200);
}

ThemeData buildAppLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    colorScheme: const ColorScheme.light(
      primary:    AppColors.orange,
      secondary:  AppColors.green,
      surface:    AppColors.lightSurface,
      onPrimary:  AppColors.black,
      onSurface:  AppColors.black,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w600,
        color: AppColors.black, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.black),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF3B3A39)),
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: AppColors.cream,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.black),
      titleTextStyle: TextStyle(
        color: AppColors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.orange : AppColors.cream,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.orange.withOpacity(0.5)
            : Colors.grey.withOpacity(0.3),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.orange,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.orange,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.black,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1F0B0B0C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1F0B0B0C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkCard,
    colorScheme: const ColorScheme.dark(
      primary:    AppColors.orange,
      secondary:  AppColors.green,
      surface:    AppColors.darkSurface,
      onPrimary:  AppColors.black,
      onSurface:  AppColors.cream,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w600,
        color: AppColors.cream, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.cream,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.cream),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.muted),
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: AppColors.cream,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.cream),
      titleTextStyle: const TextStyle(
        color: AppColors.cream,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.orange : AppColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.orange.withOpacity(0.4)
            : AppColors.cream.withOpacity(0.1),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.orange,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.orange,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.orange,
      foregroundColor: AppColors.black,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cream.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.cream.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
  );
}
