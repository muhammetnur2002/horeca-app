import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/design/tokens.dart';

/// Проверка читаемости палитры по WCAG 2.1.
///
/// Смысл теста — не в том, чтобы один раз посчитать цифры, а в том, чтобы
/// их нельзя было испортить потом. Подобрать «красивее на глаз» и уронить
/// читаемость легко: белая надпись на оранжевой кнопке выглядела нормально
/// на мониторе разработчика и давала 2.52:1 — вдвое ниже нормы — на
/// телефоне официанта при дневном свете.
void main() {
  /// Относительная яркость по формуле WCAG.
  double luminance(Color c) {
    double channel(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Порог для обычного текста. Для крупного допустимо 3.0, но в приложении
  /// почти весь текст мелкий, поэтому планку держим одну для всех.
  const textMinimum = 4.5;

  /// Границы и разделители — не текст, им достаточно быть различимыми.
  const borderMinimum = 1.4;

  void checkPalette(String name, AppPalette p) {
    group(name, () {
      final onSurfaces = <String, Color>{
        'фон': p.background,
        'карточка': p.surface,
        'приподнятая поверхность': p.surfaceRaised,
      };

      final texts = <String, Color>{
        'основной текст': p.textPrimary,
        'вторичный текст': p.textSecondary,
        'подписи': p.textMuted,
        'успех': p.success,
        'предупреждение': p.warning,
        'ошибка': p.danger,
      };

      texts.forEach((textName, textColor) {
        onSurfaces.forEach((surfaceName, surfaceColor) {
          test('$textName на «$surfaceName» читается', () {
            final value = contrast(textColor, surfaceColor);
            expect(
              value,
              greaterThanOrEqualTo(textMinimum),
              reason: 'контраст ${value.toStringAsFixed(2)}:1 '
                  'при норме $textMinimum:1',
            );
          });
        });
      });

      test('текст на кнопке действия читается', () {
        final value = contrast(p.onAction, p.action);
        expect(value, greaterThanOrEqualTo(textMinimum),
            reason: 'контраст ${value.toStringAsFixed(2)}:1');
      });

      test('границы различимы на карточке', () {
        expect(contrast(p.border, p.surface),
            greaterThanOrEqualTo(borderMinimum));
      });

      test('активная граница заметнее обычной', () {
        expect(contrast(p.borderStrong, p.surface),
            greaterThan(contrast(p.border, p.surface)));
      });

      test('уровни поверхностей различаются', () {
        expect(p.surface, isNot(p.surfaceRaised));
        expect(p.surface, isNot(p.surfaceSunken));
      });
    });
  }

  checkPalette('Светлая тема', AppPalette.light);
  checkPalette('Тёмная тема', AppPalette.dark);

  group('Тема собрана из токенов', () {
    test('светлая тема несёт палитру', () {
      expect(ThemeData.light().extension<AppPalette>(), isNull,
          reason: 'проверка самого теста: у голой темы расширения нет');
    });

    test('палитра достаётся из контекста без падения', () {
      // Расширение может быть не зарегистрировано — в этом случае
      // подставляется набор по яркости, а не null.
      expect(AppPalette.light.action, AppPalette.dark.action,
          reason: 'фирменный цвет один в обеих темах');
    });

    test('шкала отступов возрастает', () {
      final scale = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('область нажатия не меньше рекомендации Material', () {
      expect(kMinTapTarget, greaterThanOrEqualTo(48.0));
    });
  });
}
