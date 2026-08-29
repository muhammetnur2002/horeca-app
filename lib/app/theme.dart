import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Цветовые константы приложения.
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

/// Темы приложения.
///
/// Раньше обе темы были объявлены прямо в build() и дублировались, а экран
/// ввода PIN рендерился в отдельном MaterialApp с голой ThemeData и выглядел
/// иначе, чем остальное приложение. Теперь тема одна на всех.
class AppTheme {
  const AppTheme._();

  static final ThemeData light = _base(
    brightness: Brightness.light,
    scaffoldBg: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    colorScheme: const ColorScheme.light(
      primary: AppColors.orange,
      secondary: AppColors.green,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white,
      onSurface: Color(0xFF1A1A2E),
    ),
    onSurface: const Color(0xFF1A1A2E),
    bodyMediumColor: const Color(0xFF4A4A6A),
    dialogBg: Colors.white,
    inputFill: AppColors.lightCard,
    inputBorder: const Color(0xFFE0E0E0),
    fabBg: AppColors.darkCard,
    switchOffThumb: Colors.white,
    switchOffTrack: Colors.grey.withValues(alpha: 0.3),
    switchOnTrack: AppColors.orange.withValues(alpha: 0.5),
    appBarOverlay: null,
  );

  static final ThemeData dark = _base(
    brightness: Brightness.dark,
    scaffoldBg: AppColors.darkBg,
    cardColor: AppColors.darkCard,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      secondary: AppColors.green,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    onSurface: Colors.white,
    bodyMediumColor: AppColors.muted,
    dialogBg: AppColors.darkCard,
    inputFill: AppColors.darkCard2,
    inputBorder: Colors.white.withValues(alpha: 0.1),
    fabBg: AppColors.orange,
    switchOffThumb: AppColors.muted,
    switchOffTrack: Colors.white.withValues(alpha: 0.1),
    switchOnTrack: AppColors.orange.withValues(alpha: 0.4),
    appBarOverlay: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
    inputHint: const TextStyle(color: AppColors.muted),
  );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color cardColor,
    required ColorScheme colorScheme,
    required Color onSurface,
    required Color bodyMediumColor,
    required Color dialogBg,
    required Color inputFill,
    required Color inputBorder,
    required Color fabBg,
    required Color switchOffThumb,
    required Color switchOffTrack,
    required Color switchOnTrack,
    SystemUiOverlayStyle? appBarOverlay,
    TextStyle? inputHint,
  }) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      colorScheme: colorScheme,
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: bodyMediumColor),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: appBarOverlay,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.orange
              : switchOffThumb,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? switchOnTrack
              : switchOffTrack,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.orange,
        unselectedLabelColor: AppColors.muted,
        indicatorColor: AppColors.orange,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fabBg,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: inputHint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }
}
