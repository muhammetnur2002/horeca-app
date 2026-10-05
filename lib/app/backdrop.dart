/// Фон «спокойный космос»: туманности трёх акцентов палитры поверх
/// глубокого градиента, в тёмном режиме — ещё и звёзды.
///
/// Фон рисуется один раз в картинку (на палитру и режим) и подаётся
/// экранам как обычный Gradient — поэтому его можно поставить в любой
/// BoxDecoration вместо прежнего LinearGradient. Картинка масштабируется
/// по ширине и прижата к верху: у всех экранов одинаковая ширина, значит
/// фон совпадает пиксель в пиксель при переходах и под нижней панелью.
library;

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app_theme.dart';

abstract final class AkylBackdrop {
  static const _w = 600.0;
  static const _h = 1600.0;

  static final Map<String, ui.Image> _cache = {};

  static String _key(AkylPalette p, bool dark) => '${p.key}-$dark';

  /// Цвет низа фона — им же закрашена область под нижней панелью.
  static Color bottomColor(bool isDark) =>
      isDark ? AppColors.darkDeep : AppColors.lightSurface;

  /// Готовит картинки фона для палитры (оба режима). Вызывается при
  /// запуске и при смене палитры; до готовности экраны получают простой
  /// градиент тех же цветов.
  static Future<void> prepare(AkylPalette palette) async {
    for (final dark in [true, false]) {
      final key = _key(palette, dark);
      if (_cache.containsKey(key)) continue;
      _cache[key] = await _render(AkylColors.of(palette), dark);
    }
  }

  static ui.Image? imageFor(bool isDark) =>
      _cache[_key(AppColors.palette, isDark)];

  static Future<ui.Image> _render(AkylColors c, bool dark) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const rect = Rect.fromLTWH(0, 0, _w, _h);

    final top = dark ? c.darkScreen : c.lightScreen;
    final bottom = dark
        ? Color.lerp(c.darkScreen, Colors.black, 0.45)!
        : Color.lerp(c.lightScreen, Colors.white, 0.6)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, Color.lerp(top, bottom, 0.5)!, bottom],
          stops: const [0, 0.3, 0.6],
        ).createShader(rect),
    );

    void nebula(Offset o, double r, Color col, double a) {
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            col.withOpacity(a),
            col.withOpacity(a * 0.35),
            col.withOpacity(0),
          ], stops: const [0, 0.45, 1])
              .createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    final k = dark ? 1.0 : 0.75;
    nebula(const Offset(80, 120), 420, c.primary, 0.42 * k);
    nebula(const Offset(560, 520), 360, c.secondary, 0.26 * k);
    nebula(const Offset(140, 980), 380, c.tertiary, 0.18 * k);
    nebula(const Offset(520, 60), 220, c.tertiary, 0.14 * k);

    if (dark) {
      final rnd = Random(7);
      for (var i = 0; i < 140; i++) {
        final p = Offset(rnd.nextDouble() * _w, rnd.nextDouble() * _h * 0.85);
        final r = 0.4 + rnd.nextDouble() * 1.1;
        canvas.drawCircle(p, r,
            Paint()..color = Colors.white.withOpacity(0.15 + rnd.nextDouble() * 0.45));
      }
    }

    return recorder.endRecording().toImage(_w.toInt(), _h.toInt());
  }
}

/// Фон экрана как Gradient: подставляется в BoxDecoration.gradient.
class BackdropGradient extends Gradient {
  final bool isDark;

  BackdropGradient(this.isDark)
      : super(colors: AppColors.bgGradient(isDark));

  @override
  Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final image = AkylBackdrop.imageFor(isDark);
    if (image == null) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect);
    }
    // По ширине экрана, от верхнего края. Ниже картинки — её нижняя
    // строка (clamp), то есть ровный цвет низа.
    final scale = rect.width / image.width;
    final matrix = Matrix4.identity()
      ..translate(rect.left, rect.top)
      ..scale(scale, scale);
    return ImageShader(
        image, TileMode.clamp, TileMode.clamp, matrix.storage,
        filterQuality: FilterQuality.medium);
  }

  @override
  Gradient scale(double factor) => this;

  @override
  Gradient withOpacity(double opacity) => this;

  @override
  bool operator ==(Object other) =>
      other is BackdropGradient &&
      other.isDark == isDark &&
      identical(AkylBackdrop.imageFor(isDark), AkylBackdrop.imageFor(other.isDark));

  @override
  int get hashCode => Object.hash(isDark, AppColors.palette);
}
