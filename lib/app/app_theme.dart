/// Цвета приложения и светлая/тёмная темы Material. Вынесены из app.dart,
/// чтобы не раздувать его; app.dart реэкспортирует этот файл, так что
/// `import '.../app/app.dart'` по-прежнему даёт доступ к AppColors во всех
/// остальных файлах проекта без изменения их импортов.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Цветовые константы (меняй только здесь) ───────────────────────────────
class AppColors {
  // Тёмная тема
  static const darkBg       = Color(0xFF0F1629);
  static const darkSurface  = Color(0xFF1A1E2E);
  static const darkCard     = Color(0xFF242840);
  static const darkCard2    = Color(0xFF2E3352);

  // Светлая тема
  static const lightBg      = Color(0xFFEEF2FF);
  static const lightSurface = Color(0xFFF5F7FF);
  static const lightCard    = Color(0xFFFFFFFF);

  // Акцентные (общие)
  static const orange       = Color(0xFFF5862E);
  static const orangeLight  = Color(0xFFFFB067);
  static const green        = Color(0xFF639922);
  static const greenLight   = Color(0xFF97C459);
  static const muted        = Color(0xFF8B8FA8);
}

ThemeData buildAppLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    colorScheme: const ColorScheme.light(
      primary:    AppColors.orange,
      secondary:  AppColors.green,
      surface:    AppColors.lightSurface,
      onPrimary:  Colors.white,
      onSurface:  Color(0xFF1A1A2E),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E), letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A4A6A)),
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.orange : Colors.white,
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
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
      onPrimary:  Colors.white,
      onSurface:  Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w600,
        color: Colors.white, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.muted),
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
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
            : Colors.white.withOpacity(0.1),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.orange,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.orange,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
  );
}
