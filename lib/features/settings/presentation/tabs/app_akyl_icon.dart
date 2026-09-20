/// Живая анимированная иконка "Akyl" на вкладке "Приложение".
/// Вынесена из app_settings_tab.dart — самодостаточный кусок с собственной
/// анимацией и отрисовкой, не связан с остальным экраном настроек.
library;

import 'dart:math';
import 'package:flutter/material.dart';

class AkylIcon extends StatefulWidget {
  final bool isDark;
  const AkylIcon({super.key, required this.isDark});

  @override
  State<AkylIcon> createState() => _AkylIconState();
}

class _AkylIconState extends State<AkylIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: const Size(100, 100),
        painter: _AkylIconPainter(
          t: _ctrl.value * 8,
          isDark: widget.isDark,
        ),
      ),
    );
  }
}

class _AkylIconPainter extends CustomPainter {
  final double t;
  final bool isDark;
  const _AkylIconPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;

    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(22));
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.2,
          colors: isDark
              ? [
                  const Color(0xFF1A1E2E),
                  const Color(0xFF0D1128),
                  const Color(0xFF060A18)
                ]
              : [
                  const Color(0xFFEEF2FF),
                  const Color(0xFFDDE8FF),
                  const Color(0xFFC8D8FF)
                ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final orbitPaint = Paint()
      ..color = (isDark ? const Color(0xFF8C5020) : const Color(0xFFB05A10))
          .withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final rot in [-0.52, 0.52]) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w * 0.82, height: h * 0.25),
          orbitPaint);
      canvas.restore();
    }

    for (int i = 0; i < 2; i++) {
      final rot = i == 0 ? -0.52 : 0.52;
      final ang = i == 0 ? t * 0.75 - 1.57 : -t * 0.6 + 3.14;
      final r = i == 0 ? 5.5 : 4.5;
      final px = cos(ang) * w * 0.41;
      final py = sin(ang) * h * 0.125;
      final wx = cx + px * cos(rot) - py * sin(rot);
      final wy = cy + px * sin(rot) + py * cos(rot);
      canvas.drawCircle(
        Offset(wx, wy),
        r,
        Paint()
          ..shader = RadialGradient(colors: const [
            Color(0xFFFFB067),
            Color(0xFFF5862E),
          ]).createShader(Rect.fromCircle(center: Offset(wx, wy), radius: r)),
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          fontSize: w * 0.48,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 + w * 0.02));
  }

  @override
  bool shouldRepaint(_AkylIconPainter old) => old.t != t || old.isDark != isDark;
}
