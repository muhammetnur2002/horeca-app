/// Кольцо выручки на итоге смены (по макету «Орбита»): дуги — доли
/// QR-кода, карты и наличных, в центре — итоговая сумма.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

/// Цвета способов оплаты — те же точки стоят в строках итога.
abstract final class PaymentColors {
  static Color get qr => AppColors.green;
  static Color get card => AppColors.orange;
  static Color get cash => AppColors.accent3;
}

class RevenueRing extends StatelessWidget {
  final double qr;
  final double card;
  final double cash;
  final String amountText;
  final String? caption;

  const RevenueRing({
    super.key,
    required this.qr,
    required this.card,
    required this.cash,
    required this.amountText,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 230,
      height: 230,
      child: CustomPaint(
        painter: _RingPainter(
          parts: [qr, card, cash],
          colors: [PaymentColors.qr, PaymentColors.card, PaymentColors.cash],
          track: (isDark ? Colors.white : AppColors.ink).withOpacity(0.08),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('ВЫРУЧКА',
                  style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontSize: 10,
                      letterSpacing: 2,
                      color: AppColors.muted)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(amountText,
                    style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontFamilyFallback: AppFonts.fallback,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink)),
              ),
              if (caption != null) ...[
                const SizedBox(height: 4),
                Text(caption!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<double> parts;
  final List<Color> colors;
  final Color track;

  _RingPainter({required this.parts, required this.colors, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.shortestSide / 2 - stroke / 2 - 2);
    canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track);

    final total = parts.fold<double>(0, (a, b) => a + (b > 0 ? b : 0));
    if (total <= 0) return;
    final nonZero = parts.where((p) => p > 0).length;
    const gap = 0.06; // зазор между дугами, радианы
    var start = -pi / 2;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] <= 0) continue;
      final sweep = 2 * pi * parts[i] / total;
      final drawSweep = nonZero > 1 ? max(0.0, sweep - gap) : sweep;
      canvas.drawArc(
          rect,
          start + (nonZero > 1 ? gap / 2 : 0),
          drawSweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.parts.toString() != parts.toString() || old.track != track;
}
