import 'package:flutter/material.dart';

/// Семантические токены оформления.
///
/// Экраны обращаются к смыслу, а не к краске: не «оранжевый», а «цвет
/// действия», не «серый», а «второстепенный текст». Благодаря этому обе
/// темы описаны в одном месте, а не разбросаны по экранам, и заведение
/// со своим фирменным цветом настраивается подменой одного объекта.
///
/// Каждая пара «текст на фоне» проверена на контраст по WCAG 2.1:
/// обычный текст не ниже 4.5:1, границы не ниже 1.4:1. Прошлый набор
/// этого не выдерживал — белая надпись на оранжевой кнопке давала 2.52,
/// вдвое меньше нормы, и на солнце кнопка читалась с трудом.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.action,
    required this.onAction,
    required this.success,
    required this.warning,
    required this.danger,
    required this.border,
    required this.borderStrong,
  });

  /// Фон экрана.
  final Color background;

  /// Карточки и панели поверх фона.
  final Color surface;

  /// Второй уровень: поле ввода внутри карточки, выделенный элемент списка.
  final Color surfaceRaised;

  /// Углубление: полоса прогресса, неактивная область.
  final Color surfaceSunken;

  final Color textPrimary;

  /// Пояснения и подписи под заголовками.
  final Color textSecondary;

  /// Единицы измерения, даты, служебные пометки.
  ///
  /// Проверяется на всех трёх поверхностях, а не только на карточке:
  /// первый подобранный оттенок читался на белой карточке, но проваливался
  /// на голубоватом фоне экрана — 4.32 при норме 4.5. Тест это поймал.
  final Color textMuted;

  /// Цвет главного действия. Фирменный оранжевый.
  final Color action;

  /// Текст и значки поверх [action]. Тёмный, а не белый: так фирменный
  /// оранжевый остаётся ровно тем же, а надпись становится читаемой.
  final Color onAction;

  /// Смысловые цвета состояния. Отдельны от [action] намеренно:
  /// «успешно» не должно выглядеть как «нажми сюда».
  final Color success;
  final Color warning;
  final Color danger;

  /// Разделители и обводка полей.
  final Color border;

  /// Обводка активного элемента.
  final Color borderStrong;

  static const light = AppPalette(
    background:    Color(0xFFEEF2FF),
    surface:       Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF5F7FF),
    surfaceSunken: Color(0xFFE4E9F7),
    textPrimary:   Color(0xFF16192B),
    textSecondary: Color(0xFF53596F),
    textMuted:     Color(0xFF62677D),
    action:        Color(0xFFF5862E),
    onAction:      Color(0xFF1F1206),
    success:       Color(0xFF3E6B14),
    warning:       Color(0xFF8A5A00),
    danger:        Color(0xFFB3261E),
    border:        Color(0xFFD2D9EC),
    borderStrong:  Color(0xFFA9B4D2),
  );

  static const dark = AppPalette(
    background:    Color(0xFF0F1629),
    surface:       Color(0xFF1A1E2E),
    surfaceRaised: Color(0xFF242840),
    surfaceSunken: Color(0xFF0A0F1E),
    textPrimary:   Color(0xFFF2F4FA),
    textSecondary: Color(0xFFB4BBD0),
    textMuted:     Color(0xFF8E96AE),
    action:        Color(0xFFF5862E),
    onAction:      Color(0xFF1F1206),
    success:       Color(0xFF9BD35F),
    warning:       Color(0xFFE8B54B),
    danger:        Color(0xFFF09184),
    border:        Color(0xFF323A55),
    borderStrong:  Color(0xFF4C567A),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? action,
    Color? onAction,
    Color? success,
    Color? warning,
    Color? danger,
    Color? border,
    Color? borderStrong,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      action: mix(action, other.action),
      onAction: mix(onAction, other.onAction),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
    );
  }
}

/// Шкала отступов. Кратна четырём: произвольные значения вроде 13 или 17
/// на глаз незаметны поодиночке, но вместе дают ощущение неаккуратности.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Скругления. Три значения, каждое со своей ролью.
class AppRadii {
  const AppRadii._();

  /// Мелкие элементы: плашки, значки, поля ввода.
  static const sm = 12.0;

  /// Кнопки и карточки.
  static const md = 16.0;

  /// То, что всплывает поверх экрана: диалоги, нижние панели.
  static const lg = 20.0;
}

/// Минимальный размер области нажатия.
///
/// Рекомендация Material — 48 логических пикселей. В зале официант
/// нажимает на бегу и часто мокрым пальцем, поэтому меньше делать нельзя,
/// даже если значок визуально мелкий.
const double kMinTapTarget = 48.0;

extension AppPaletteContext on BuildContext {
  /// Палитра текущей темы.
  ///
  /// Если расширение почему-то не зарегистрировано, возвращается набор,
  /// соответствующий яркости темы: лучше показать правильные цвета,
  /// чем упасть на null.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark ? AppPalette.dark : AppPalette.light);
  }
}
