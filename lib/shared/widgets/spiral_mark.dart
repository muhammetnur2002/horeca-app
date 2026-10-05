/// Знак «Спираль» — символ Akyl: приход закручивается внутрь, расход
/// раскручивается наружу, а ядро с уровнем внутри — это остаток
/// (остаток = начало + приход − расход). Используется на заставке и в
/// карточке приложения в Настройках; цвета берутся из текущей палитры.
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app_theme.dart';

/// Анимированный знак. [drawIn] — проиграть «прорисовку» спиралей при
/// появлении; после неё знак медленно живёт (волна в ядре, бег точек).
class SpiralMark extends StatefulWidget {
  final double size;
  final bool drawIn;
  final Duration drawDuration;
  /// Явный режим — для мест вне MaterialApp (заставка), где Theme ещё нет.
  final bool? isDark;

  const SpiralMark({
    super.key,
    this.size = 100,
    this.isDark,
    this.drawIn = false,
    this.drawDuration = const Duration(milliseconds: 1100),
  });

  @override
  State<SpiralMark> createState() => _SpiralMarkState();
}

class _SpiralMarkState extends State<SpiralMark> with TickerProviderStateMixin {
  late final AnimationController _draw;
  late final AnimationController _life;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(vsync: this, duration: widget.drawDuration);
    _life = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    if (widget.drawIn) {
      _draw.forward();
    } else {
      _draw.value = 1;
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.isDark ?? Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_draw, _life]),
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: SpiralMarkPainter(
            progress: Curves.easeOutCubic.transform(_draw.value),
            phase: _life.value,
            colors: AppColors.current,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

/// Отрисовка знака в квадрате любого размера (геометрия задана в сетке
/// 120×120). [progress] 0..1 — доля прорисовки спиралей, [phase] 0..1 —
/// цикл «жизни» (волна уровня и бегущие точки).
class SpiralMarkPainter extends CustomPainter {
  final double progress;
  final double phase;
  final AkylColors colors;
  final bool isDark;

  const SpiralMarkPainter({
    required this.progress,
    required this.phase,
    required this.colors,
    required this.isDark,
  });

  static const _turn = 1.55 * pi;
  static const _rot = -18 * pi / 180;

  /// Точки спирали в сетке 120: приход идёт с внешнего радиуса 52 к 16,
  /// расход — от 16 наружу к 52, с противоположной стороны.
  static List<Offset> spiralPoints(bool inward, {int n = 90}) {
    final pts = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      final r = inward ? 52 - 36 * u : 16 + 36 * u;
      final th = _rot + (inward ? u * _turn : pi + u * _turn);
      pts.add(Offset(60 + r * cos(th), 60 + r * sin(th) * 0.5));
    }
    return pts;
  }

  Path _path(List<Offset> pts, double s) {
    final p = Path()..moveTo(pts.first.dx * s, pts.first.dy * s);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx * s, o.dy * s);
    }
    return p;
  }

  Path _partial(Path full, double t) {
    final out = Path();
    for (final m in full.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    return out;
  }

  Offset _pointAt(Path full, double t) {
    final m = full.computeMetrics().first;
    return m.getTangentForOffset(m.length * t.clamp(0.0, 1.0))!.position;
  }

  void _stroke(Canvas canvas, Path full, Color c, double s) {
    final part = _partial(full, progress);
    canvas.drawPath(
      part,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6 * s
        ..color = c.withOpacity(isDark ? 0.35 : 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * s),
    );
    canvas.drawPath(
      part,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2 * s
        ..color = c,
    );
    if (progress < 1) return;
    // Бегущие «единицы товара» вдоль спирали.
    for (var k = 0; k < 3; k++) {
      final t = (phase + k / 3) % 1.0;
      canvas.drawCircle(_pointAt(full, t), 1.8 * s,
          Paint()..color = Colors.white.withOpacity(0.85 * sin(pi * t)));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    final inPath = _path(spiralPoints(true), s);
    final outPath = _path(spiralPoints(false), s);

    _stroke(canvas, inPath, colors.inflow, s);
    _stroke(canvas, outPath, colors.outflow, s);

    // Планеты на внешних концах: откуда приходит и куда уходит.
    final pIn = spiralPoints(true).first * s;
    final pOut = spiralPoints(false).last * s;
    canvas.drawCircle(pIn, 4.2 * s, Paint()..color = colors.inflow);
    if (progress > 0.95) {
      canvas.drawCircle(
          pOut,
          4.2 * s * ((progress - 0.95) / 0.05),
          Paint()..color = colors.outflow);
    }

    // Ядро — остаток: кольцо с «жидким» уровнем внутри.
    final c = Offset(60 * s, 60 * s);
    final coreR = 13 * s;
    final appear = (progress * 1.6).clamp(0.0, 1.0);
    canvas.drawCircle(
        c,
        coreR + 5 * s,
        Paint()
          ..color = colors.primary.withOpacity(0.25 * appear)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * s));
    canvas.drawCircle(
        c,
        coreR,
        Paint()
          ..color = (isDark ? colors.darkScreen : Colors.white)
              .withOpacity(0.9 * appear));

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: c, radius: coreR - 2.2 * s)));
    final level = c.dy + coreR * (0.9 - 0.75 * progress); // поднимается
    final wave = Path()..moveTo(c.dx - coreR, c.dy + coreR);
    for (var x = -coreR; x <= coreR; x += s) {
      final y = level +
          sin(x / coreR * 2.4 * pi + phase * 2 * pi) * 1.6 * s;
      wave.lineTo(c.dx + x, y);
    }
    wave
      ..lineTo(c.dx + coreR, c.dy + coreR)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.primaryLight, colors.primary],
        ).createShader(Rect.fromCircle(center: c, radius: coreR)),
    );
    canvas.restore();

    canvas.drawCircle(
        c,
        coreR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * s
          ..color = colors.primaryLight.withOpacity(appear));
  }

  @override
  bool shouldRepaint(SpiralMarkPainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.colors != colors ||
      old.isDark != isDark;
}
