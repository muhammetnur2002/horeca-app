/// Фон заставки: градиент и туманности текущей палитры, мерцающие звёзды
/// и подпись «Akyl». Сам знак «Спираль» рисуется поверх виджетом
/// SpiralMark (lib/shared/widgets/spiral_mark.dart).
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

class Star {
  final double x, y, r, phase, speed;
  const Star({required this.x, required this.y, required this.r,
      required this.phase, required this.speed});
}

class SplashBackgroundPainter extends CustomPainter {
  /// Прошедшие секунды с начала заставки.
  final double t;
  final bool isDark;
  final List<Star> stars;

  const SplashBackgroundPainter({
    required this.t,
    required this.isDark,
    required this.stars,
  });

  double _ph(double s, double e) => ((t - s) / (e - s)).clamp(0.0, 1.0);
  double _eo(double v) => 1 - pow(1 - v, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final c = AppColors.current;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkDeep, AppColors.darkBg, AppColors.darkGrad2]
              : [AppColors.lightSurface, AppColors.lightBg, AppColors.lightSurface],
        ).createShader(rect),
    );

    // Туманности трёх акцентов палитры.
    void nebula(Offset o, double r, Color col, double a) {
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            col.withOpacity(a),
            col.withOpacity(0),
          ]).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    final drift = sin(t * 0.8) * 8;
    nebula(Offset(w * 0.2 + drift, h * 0.25), w * 0.6, c.primary,
        isDark ? 0.28 : 0.16);
    nebula(Offset(w * 0.85, h * 0.6 - drift), w * 0.55, c.secondary,
        isDark ? 0.20 : 0.12);
    nebula(Offset(w * 0.4, h * 0.95), w * 0.5, c.tertiary,
        isDark ? 0.14 : 0.10);

    final starCol = isDark ? Colors.white : c.primary;
    for (final s in stars) {
      final a = (0.35 + 0.65 * (0.5 + 0.5 * sin(t * s.speed * 3 + s.phase))) *
          (isDark ? 0.9 : 0.35);
      canvas.drawCircle(Offset(s.x * w, s.y * h), s.r,
          Paint()..color = starCol.withOpacity(a));
    }

    // Подпись.
    final p = _eo(_ph(0.6, 1.3));
    if (p <= 0) return;
    final textCol = isDark ? Colors.white : AppColors.ink;
    final tp1 = TextPainter(
      text: TextSpan(
          text: 'Akyl',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: textCol.withOpacity(p),
            letterSpacing: -1.5,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    final ty = h * 0.66 + (1 - p) * 12;
    tp1.paint(canvas, Offset((w - tp1.width) / 2, ty));

    final tp2 = TextPainter(
      text: TextSpan(
          text: 'управляй с умом',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: (isDark ? c.primaryLight : c.primary).withOpacity(p),
            letterSpacing: 1.5,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset((w - tp2.width) / 2, ty + 54));

    for (var i = 0; i < 3; i++) {
      final dt = (t * 1.2 - i * 0.33) % 1.0;
      final k = 1 - (dt * 2 - 1).abs();
      canvas.drawCircle(
        Offset(w / 2 - 18 + i * 18.0, h * 0.88),
        5 * (0.7 + 0.3 * k),
        Paint()..color = AppColors.orange.withOpacity((0.25 + 0.75 * k) * p),
      );
    }
  }

  @override
  bool shouldRepaint(SplashBackgroundPainter old) =>
      old.t != t || old.isDark != isDark;
}
