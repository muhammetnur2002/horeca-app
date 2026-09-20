/// Анимированное мини-лого "Akyl" в AppBar главного экрана.
/// Вынесено из home_screen.dart.
library;

import 'dart:math';
import 'package:flutter/material.dart';

class AkylLogoTitle extends StatefulWidget {
  final bool isDark;
  const AkylLogoTitle({super.key, required this.isDark});
  @override
  State<AkylLogoTitle> createState() => _AkylLogoTitleState();
}

class _AkylLogoTitleState extends State<AkylLogoTitle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: const Size(36, 36),
            painter: _MiniLogoPainter(t: _ctrl.value * 8, isDark: widget.isDark),
          ),
        ),
      ],
    );
  }
}

class _MiniLogoPainter extends CustomPainter {
  final double t;
  final bool isDark;
  const _MiniLogoPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;

    // фон
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), Radius.circular(w * 0.22));
    canvas.clipRRect(rrect);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = RadialGradient(
                  colors: isDark
                      ? [const Color(0xFF1A1E2E), const Color(0xFF060A18)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFC8D8FF)])
              .createShader(Rect.fromLTWH(0, 0, w, h)));

    // орбиты
    final orbitPaint = Paint()
      ..color = (isDark ? const Color(0xFF8C5020) : const Color(0xFFB05A10))
          .withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final rot in [-0.52, 0.52]) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w * 0.88, height: h * 0.28),
          orbitPaint);
      canvas.restore();
    }

    // планеты
    for (int i = 0; i < 2; i++) {
      final rot = i == 0 ? -0.52 : 0.52;
      final ang = i == 0 ? t * 0.75 - pi * 0.5 : -t * 0.6 + pi;
      final r = i == 0 ? w * 0.11 : w * 0.09;
      final px = cos(ang) * w * 0.44;
      final py = sin(ang) * h * 0.14;
      final wx = cx + px * cos(rot) - py * sin(rot);
      final wy = cy + px * sin(rot) + py * cos(rot);
      canvas.drawCircle(
          Offset(wx, wy),
          r,
          Paint()
            ..shader = RadialGradient(colors: const [Color(0xFFFFB067), Color(0xFFF5862E)])
                .createShader(Rect.fromCircle(center: Offset(wx, wy), radius: r)));
    }

    // буква A
    final tp = TextPainter(
      text: TextSpan(
          text: 'A',
          style: TextStyle(
            fontSize: w * 0.5,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          )),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 + w * 0.02));
  }

  @override
  bool shouldRepaint(_MiniLogoPainter old) => old.t != t || old.isDark != isDark;
}
