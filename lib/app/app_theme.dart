/// Цвета приложения и светлая/тёмная темы Material. Вынесены из app.dart,
/// чтобы не раздувать его; app.dart реэкспортирует этот файл, так что
/// `import '.../app/app.dart'` по-прежнему даёт доступ к AppColors во всех
/// остальных файлах проекта без изменения их импортов.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Палитры оформления ────────────────────────────────────────────────────
/// Пять тем оформления «Akyl». Каждая задаёт фон, стекло и акценты для
/// тёмного и светлого режима; логика экранов от выбора темы не зависит.
enum AkylPalette {
  orbit('orbit', 'Орбита'),
  aurora('aurora', 'Северное сияние'),
  mars('mars', 'Закат на Марсе'),
  moon('moon', 'Лунный свет'),
  galaxy('galaxy', 'Галактика');

  final String key;
  final String title;
  const AkylPalette(this.key, this.title);

  static AkylPalette fromKey(String? key) => AkylPalette.values
      .firstWhere((p) => p.key == key, orElse: () => AkylPalette.orbit);
}

/// Набор цветов одной темы.
class AkylColors {
  final Color darkScreen;
  final Color lightScreen;
  /// Основной акцент (кнопки, выделение) — с белым текстом поверх.
  final Color primary;
  final Color primaryLight;
  /// Второй акцент (успех, «приход»).
  final Color secondary;
  final Color secondaryLight;
  /// Третий акцент (подсветки, «расход» на знаке).
  final Color tertiary;
  final Color muted;
  /// Основной цвет текста в светлом режиме.
  final Color ink;
  /// Цвета знака «Спираль»: приход и расход.
  final Color inflow;
  final Color outflow;

  const AkylColors({
    required this.darkScreen,
    required this.lightScreen,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.secondaryLight,
    required this.tertiary,
    required this.muted,
    required this.ink,
    required this.inflow,
    required this.outflow,
  });

  static AkylColors of(AkylPalette p) => switch (p) {
        AkylPalette.orbit => const AkylColors(
            darkScreen: Color(0xFF0D1030),
            lightScreen: Color(0xFFF1EFFF),
            primary: Color(0xFF6E5CF6),
            primaryLight: Color(0xFF9D90FF),
            secondary: Color(0xFF1FB5C9),
            secondaryLight: Color(0xFF4DE3F2),
            tertiary: Color(0xFFFF7AB8),
            muted: Color(0xFF8C8AB4),
            ink: Color(0xFF1B1640),
            inflow: Color(0xFF4DE3F2),
            outflow: Color(0xFFFF8A6A),
          ),
        AkylPalette.aurora => const AkylColors(
            darkScreen: Color(0xFF06141A),
            lightScreen: Color(0xFFEAF8F3),
            primary: Color(0xFF6A6FF0),
            primaryLight: Color(0xFF9C7BFF),
            secondary: Color(0xFF14A97F),
            secondaryLight: Color(0xFF2FE6A8),
            tertiary: Color(0xFFFF8FB1),
            muted: Color(0xFF7E9E98),
            ink: Color(0xFF0C2A26),
            inflow: Color(0xFF2FE6A8),
            outflow: Color(0xFFFF8FB1),
          ),
        AkylPalette.mars => const AkylColors(
            darkScreen: Color(0xFF1A0B14),
            lightScreen: Color(0xFFFFF1EA),
            primary: Color(0xFFE2474F),
            primaryLight: Color(0xFFFF6A6A),
            secondary: Color(0xFFD9822B),
            secondaryLight: Color(0xFFFFB86B),
            tertiary: Color(0xFFC86BFF),
            muted: Color(0xFFAA8A92),
            ink: Color(0xFF2A1218),
            inflow: Color(0xFFFFB86B),
            outflow: Color(0xFFC86BFF),
          ),
        AkylPalette.moon => const AkylColors(
            darkScreen: Color(0xFF0C0F16),
            lightScreen: Color(0xFFEFF2F8),
            primary: Color(0xFF4A6FC8),
            primaryLight: Color(0xFF8FB8FF),
            secondary: Color(0xFF3A8FD8),
            secondaryLight: Color(0xFFBFD4FF),
            tertiary: Color(0xFFF2A7C3),
            muted: Color(0xFF8A93A8),
            ink: Color(0xFF1A2233),
            inflow: Color(0xFFBFD4FF),
            outflow: Color(0xFFF2A7C3),
          ),
        AkylPalette.galaxy => const AkylColors(
            darkScreen: Color(0xFF0A0620),
            lightScreen: Color(0xFFF8F0FF),
            primary: Color(0xFFD32FB4),
            primaryLight: Color(0xFFFF4FD8),
            secondary: Color(0xFF1F9AE0),
            secondaryLight: Color(0xFF59C8FF),
            tertiary: Color(0xFFFFE066),
            muted: Color(0xFF9C8CC0),
            ink: Color(0xFF241040),
            inflow: Color(0xFF59C8FF),
            outflow: Color(0xFFFFE066),
          ),
      };
}

/// Шрифты оформления (встроены в приложение, работают без интернета).
abstract final class AppFonts {
  /// Основной текст.
  static const text = 'Manrope';

  /// Крупные заголовки.
  static const display = 'Unbounded';

  /// Количества и суммы — цифры одной ширины, столбцы ровные.
  static const mono = 'JetBrainsMono';
}

// ─── Цвета приложения ──────────────────────────────────────────────────────
/// Цвета текущей темы. Раньше это были константы; теперь значения берутся
/// из выбранной палитры (меняется в Настройках → Приложение), имена прежние,
/// чтобы экраны не пришлось переписывать.
class AppColors {
  static AkylPalette _palette = AkylPalette.orbit;
  static AkylColors _c = AkylColors.of(AkylPalette.orbit);

  static AkylPalette get palette => _palette;
  static AkylColors get current => _c;

  static void applyPalette(AkylPalette p) {
    _palette = p;
    _c = AkylColors.of(p);
  }

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  // Тёмная тема
  static Color get darkBg => _c.darkScreen;
  static Color get darkSurface => _mix(_c.darkScreen, Colors.white, 0.05);
  static Color get darkCard =>
      _mix(_mix(_c.darkScreen, _c.primary, 0.12), Colors.white, 0.08);
  static Color get darkCard2 =>
      _mix(_mix(_c.darkScreen, _c.primary, 0.18), Colors.white, 0.14);
  /// Второй и третий цвет фонового градиента в тёмном режиме.
  static Color get darkGrad2 => _mix(_c.darkScreen, _c.primary, 0.16);
  static Color get darkGrad3 => _mix(_c.darkScreen, _c.secondary, 0.10);
  /// Самый глубокий оттенок фона (заставка, тени логотипа).
  static Color get darkDeep => _mix(_c.darkScreen, Colors.black, 0.45);

  // Светлая тема
  static Color get lightBg => _c.lightScreen;
  static Color get lightSurface => _mix(_c.lightScreen, Colors.white, 0.6);
  static const lightCard = Color(0xFFFFFFFF);
  /// Основной цвет текста в светлом режиме.
  static Color get ink => _c.ink;
  static Color get inkSoft => _mix(_c.ink, _c.muted, 0.5);

  // Акцентные (общие). Имена исторические: orange — основной акцент темы,
  // green — второй.
  static Color get orange => _c.primary;
  static Color get orangeLight => _c.primaryLight;
  static Color get green => _c.secondary;
  static Color get greenLight => _c.secondaryLight;
  static Color get accent3 => _c.tertiary;
  static Color get muted => _c.muted;

  /// Цвета фонового градиента экранов.
  static List<Color> bgGradient(bool isDark) => isDark
      ? [darkBg, darkGrad2, darkGrad3]
      : [lightBg, lightSurface, lightBg];
}

ThemeData buildAppLightTheme() {
  return ThemeData(
    fontFamily: AppFonts.text,
    // Экраны рисуют свой фон-туманность; под ними — цвет низа фона.
    brightness: Brightness.light,
    useMaterial3: true,
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    colorScheme: ColorScheme.light(
      primary:    AppColors.orange,
      secondary:  AppColors.green,
      surface:    AppColors.lightSurface,
      onPrimary:  Colors.white,
      onSurface:  AppColors.ink,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 26, fontWeight: FontWeight.w600,
        color: AppColors.ink, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.inkSoft),
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
      iconTheme: IconThemeData(color: AppColors.ink),
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.display,
        letterSpacing: -0.2,
        color: AppColors.ink,
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
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.orange,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.orange,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
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
        borderSide: BorderSide(color: AppColors.orange, width: 1.5),
      ),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    fontFamily: AppFonts.text,
    // Экраны рисуют свой фон-туманность; под ними — цвет низа фона.
    brightness: Brightness.dark,
    useMaterial3: true,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkCard,
    colorScheme: ColorScheme.dark(
      primary:    AppColors.orange,
      secondary:  AppColors.green,
      surface:    AppColors.darkSurface,
      onPrimary:  Colors.white,
      onSurface:  Colors.white,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 26, fontWeight: FontWeight.w600,
        color: Colors.white, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.display,
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
        fontFamily: AppFonts.display,
        letterSpacing: -0.2,
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
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.orange,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.orange,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
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
        borderSide: BorderSide(color: AppColors.orange, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.muted),
    ),
  );
}
