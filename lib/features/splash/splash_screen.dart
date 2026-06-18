import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rnd = Random(42);

  // звёзды
  late List<_Star> _stars;
  // частицы
  final List<_Particle> _particles = [];
  // метеориты
  final List<_Shoot> _shoots = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _stars = List.generate(160, (i) => _Star(
      x: _rnd.nextDouble(),
      y: _rnd.nextDouble(),
      r: 0.3 + _rnd.nextDouble() * 1.4,
      phase: _rnd.nextDouble() * pi * 2,
      speed: 0.4 + _rnd.nextDouble() * 1.2,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isDark {
    final themeMode = ref.read(themeModeProvider);
    if (themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060A18) : const Color(0xFFDDE8FF),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 10; // 0..10 секунд
          _updateParticles();
          _maybeShoot();
          return CustomPaint(
            painter: _GalaxyPainter(
              t: t,
              isDark: isDark,
              stars: _stars,
              particles: List.from(_particles),
              shoots: List.from(_shoots),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  void _updateParticles() {
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.3;
      p.vx *= 0.97;
      p.life -= p.decay;
    }
  }

  void _maybeShoot() {
    _shoots.removeWhere((s) => s.life <= 0);
    if (_rnd.nextDouble() < 0.02 && _shoots.length < 4) {
      final angle = _rnd.nextDouble() * 0.3 + 0.1;
      final speed = _rnd.nextDouble() * 8 + 10;
      _shoots.add(_Shoot(
        x: _rnd.nextDouble() * 400,
        y: _rnd.nextDouble() * 150,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 1.0,
      ));
    }
  }
}

// ── Модели ────────────────────────────────────────────────────────────────
class _Star {
  final double x, y, r, phase, speed;
  const _Star({required this.x, required this.y, required this.r,
      required this.phase, required this.speed});
}

class _Particle {
  double x, y, vx, vy, life, decay;
  final Color color;
  final double r;
  _Particle({required this.x, required this.y, required this.vx,
      required this.vy, required this.life, required this.decay,
      required this.color, required this.r});
}

class _Shoot {
  double x, y, vx, vy, life;
  _Shoot({required this.x, required this.y, required this.vx,
      required this.vy, required this.life});
}

// ── Painter ───────────────────────────────────────────────────────────────
class _GalaxyPainter extends CustomPainter {
  final double t;
  final bool isDark;
  final List<_Star> stars;
  final List<_Particle> particles;
  final List<_Shoot> shoots;

  const _GalaxyPainter({
    required this.t,
    required this.isDark,
    required this.stars,
    required this.particles,
    required this.shoots,
  });

  // прогресс фазы
  double ph(double s, double e) => ((t - s) / (e - s)).clamp(0.0, 1.0);
  double eo(double v, [double p = 3]) => 1 - pow(1 - v.clamp(0, 1), p).toDouble();

  // цвета
  Color get _orbitCol => isDark
      ? const Color(0xFF8C5020).withOpacity(1)
      : const Color(0xFFB05A10).withOpacity(1);
  Color get _Acol => isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _textCol => isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _tagCol => isDark ? AppColors.orange : const Color(0xFFC85000);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final CX = W / 2, CY = H / 2;

    _drawBg(canvas, size, CX, CY, W, H);
    _drawOrbits(canvas, CX, CY, W, H);
    _drawDotRing(canvas, CX, CY, W);
    _drawShoots(canvas);
    _drawPlanets(canvas, CX, CY, W, H);
    _drawParticles(canvas);
    _drawBurst(canvas, CX, CY, W, H);
    _drawA(canvas, CX, CY, W);
    _drawPulseRings(canvas, CX, CY, W);
    _drawText(canvas, CX, CY, H);
  }

  void _drawBg(Canvas canvas, Size size, double CX, double CY, double W, double H) {
    // радиальный фон
    final bg = RadialGradient(
      center: Alignment(0, -0.2),
      radius: 1.2,
      colors: isDark
          ? [const Color(0xFF1A1E2E), const Color(0xFF0D1128), const Color(0xFF060A18)]
          : [const Color(0xFFEEF2FF), const Color(0xFFDDE8FF), const Color(0xFFC8D8FF)],
    ).createShader(Rect.fromLTWH(0, 0, W, H));
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..shader = bg);

    // туманности
    final nebColors = isDark
        ? [const Color(0xFF0F1629), const Color(0xFF140C32)]
        : [const Color(0xFFC8DAFF), const Color(0xFFDCE8FF)];
    _drawNebula(canvas, CX * 0.5, CY * 0.5, W * 0.3, nebColors[0].withOpacity(isDark ? 0.3 : 0.6));
    _drawNebula(canvas, CX * 1.5, CY * 1.4, W * 0.25, nebColors[1].withOpacity(isDark ? 0.25 : 0.5));

    // звёзды
    for (final s in stars) {
      final opacity = (isDark ? 0.07 : 0.05) + 0.09 * sin(t * s.speed + s.phase);
      canvas.drawCircle(
        Offset(s.x * W, s.y * H),
        s.r * (isDark ? 1 : 0.45),
        Paint()..color = (isDark ? Colors.white : const Color(0xFF5060C8)).withOpacity(opacity.clamp(0, 1)),
      );
    }

    // виньетка
    final vig = RadialGradient(
      radius: 0.85,
      colors: [
        Colors.transparent,
        isDark ? const Color(0xFF00000A).withOpacity(0.65) : const Color(0xFFB4C8F0).withOpacity(0.3),
      ],
    ).createShader(Rect.fromLTWH(0, 0, W, H));
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()..shader = vig);
  }

  void _drawNebula(Canvas canvas, double x, double y, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withOpacity(0)])
          .createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
    canvas.drawCircle(Offset(x, y), r, paint);
  }

  void _drawOrbits(Canvas canvas, double CX, double CY, double W, double H) {
    final p = eo(ph(0.3, 1.8));
    if (p <= 0) return;
    final settle = eo(ph(4.5, 6.2));
    final alpha = p * (isDark ? lerpDouble(0.62, 0.25, settle) : lerpDouble(0.55, 0.2, settle));

    final paint = Paint()
      ..color = _orbitCol.withOpacity(alpha.clamp(0, 1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final rot in [-0.52, 0.52]) {
      canvas.save();
      canvas.translate(CX, CY);
      canvas.rotate(rot);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: W * 0.64 * p,
        height: H * 0.2 * p,
      );
      canvas.drawOval(rect, paint);
      canvas.restore();
    }
  }

  void _drawDotRing(Canvas canvas, double CX, double CY, double W) {
    final p = eo(ph(0.3, 1.8));
    if (p <= 0) return;
    final settle = eo(ph(4.5, 6.2));
    const n = 14;
    final R = W * 0.4 * p;
    for (int i = 0; i < n; i++) {
      final a = pi * 2 / n * i + t * 0.2;
      final pulse = 0.35 + 0.24 * sin(t * 2.2 + i * 0.45);
      final alpha = (pulse * lerpDouble(0.55, 0.12, settle)).clamp(0, 1);
      canvas.drawCircle(
        Offset(CX + cos(a) * R, CY + sin(a) * R),
        4.5,
        Paint()..color = _orbitCol.withOpacity(alpha.toDouble()),
      );
    }
  }

  void _drawPlanets(Canvas canvas, double CX, double CY, double W, double H) {
    final p = eo(ph(0.3, 1.8));
    final settle = eo(ph(4.5, 6.2));
    final planets = [
      _PlanetDef(rx: W * 0.32, ry: H * 0.1, rot: -0.52,
          ang: t * 0.75 - pi * 0.5, r: 11,
          c0: const Color(0xFFFFB067), c1: const Color(0xFFF5862E)),
      _PlanetDef(rx: W * 0.32, ry: H * 0.1, rot: 0.52,
          ang: -t * 0.6 + pi, r: 9,
          c0: const Color(0xFFFFCC80), c1: const Color(0xFFCC7020)),
    ];
    for (int i = 0; i < planets.length; i++) {
      final pp = eo(((p - i * 0.12) * 1.6).clamp(0, 1));
      if (pp <= 0) continue;
      final pl = planets[i];
      final px = cos(pl.ang) * pl.rx;
      final py = sin(pl.ang) * pl.ry;
      final wx = CX + px * cos(pl.rot) - py * sin(pl.rot);
      final wy = CY + px * sin(pl.rot) + py * cos(pl.rot);
      final r = pl.r * pp;
      final shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [pl.c0, pl.c1],
      ).createShader(Rect.fromCircle(center: Offset(wx, wy), radius: r));
      canvas.drawCircle(Offset(wx, wy), r, Paint()..shader = shader);
    }
  }

  void _drawA(Canvas canvas, double CX, double CY, double W) {
    final p = eo(ph(0.05, 0.85), 4);
    if (p <= 0) return;
    final settle = eo(ph(4.5, 6.2));
    canvas.save();
    canvas.translate(CX, CY);
    canvas.scale(p, p);

    // свечение
    final gr = RadialGradient(colors: [
      AppColors.orange.withOpacity(lerpDouble(0.12, 0.04, settle)),
      Colors.transparent,
    ]).createShader(Rect.fromCircle(center: Offset.zero, radius: W * 0.14));
    canvas.drawCircle(Offset.zero, W * 0.14, Paint()..shader = gr);

    // рисуем A через TextPainter
    final tp = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          fontSize: W * 0.44,
          fontWeight: FontWeight.w900,
          color: _Acol,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 + W * 0.02));

    canvas.restore();
  }

  void _drawBurst(Canvas canvas, double CX, double CY, double W, double H) {
    final p = ph(0, 0.35);
    if (p <= 0) return;
    final fade = p < 0.3 ? p / 0.3 : 1 - (p - 0.3) / 0.7;
    final shader = RadialGradient(colors: [
      const Color(0xFFFFE896).withOpacity(fade * 0.8),
      AppColors.orange.withOpacity(fade * 0.4),
      Colors.transparent,
    ], stops: const [0, 0.3, 1]).createShader(
      Rect.fromCircle(center: Offset(CX, CY), radius: eo(p, 2) * W * 0.36));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, W, H), Paint()..shader = shader);
  }

  void _drawPulseRings(Canvas canvas, double CX, double CY, double W) {
    for (int i = 0; i < 3; i++) {
      final p = ph(5.0 + i * 0.65, 7.0 + i * 0.65);
      if (p <= 0) continue;
      final fade = 1 - p;
      final r = lerpDouble(W * 0.08, W * 0.48, eo(p, 2));
      canvas.drawCircle(
        Offset(CX, CY), r,
        Paint()
          ..color = AppColors.orange.withOpacity(fade * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (3 * (1 - p) + 0.5),
      );
    }
  }

  void _drawText(Canvas canvas, double CX, double CY, double H) {
    final p = eo(ph(4.8, 6.2));
    if (p <= 0) return;

    // Akyl
    final tp1 = TextPainter(
      text: TextSpan(text: 'Akyl', style: TextStyle(
        fontSize: 44, fontWeight: FontWeight.w800,
        color: _textCol.withOpacity(p), letterSpacing: -1.5,
      )),
      textDirection: TextDirection.ltr,
    );
    tp1.layout();
    tp1.paint(canvas, Offset(CX - tp1.width / 2, H * 0.72));

    // слоган
    final tp2 = TextPainter(
      text: TextSpan(text: 'управляй с умом', style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: _tagCol.withOpacity(p), letterSpacing: 1.5,
      )),
      textDirection: TextDirection.ltr,
    );
    tp2.layout();
    tp2.paint(canvas, Offset(CX - tp2.width / 2, H * 0.72 + 52));

    // точки загрузки
    for (int i = 0; i < 3; i++) {
      final dt = (t * 0.33 - i * 0.33) % 1.0;
      final dotAlpha = (0.25 + 0.75 * (1 - (dt * 2 - 1).abs())).clamp(0.2, 1.0) * p;
      final dotScale = (0.7 + 0.3 * (1 - (dt * 2 - 1).abs())).clamp(0.7, 1.0);
      canvas.drawCircle(
        Offset(CX - 18 + i * 18.0, H * 0.88),
        5 * dotScale,
        Paint()..color = AppColors.orange.withOpacity(dotAlpha),
      );
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      canvas.drawCircle(
        Offset(p.x, p.y), p.r,
        Paint()..color = p.color.withOpacity(p.life * p.life),
      );
    }
  }

  void _drawShoots(Canvas canvas) {
    for (final s in shoots) {
      if (s.life <= 0) continue;
      final paint = Paint()
        ..shader = LinearGradient(colors: [
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(s.life * 0.6),
        ]).createShader(Rect.fromPoints(
          Offset(s.x - s.vx * 3, s.y - s.vy * 3), Offset(s.x, s.y)))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(s.x - s.vx * 3, s.y - s.vy * 3),
        Offset(s.x, s.y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GalaxyPainter old) => true;
}

class _PlanetDef {
  final double rx, ry, rot, ang, r;
  final Color c0, c1;
  const _PlanetDef({required this.rx, required this.ry, required this.rot,
      required this.ang, required this.r, required this.c0, required this.c1});
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;