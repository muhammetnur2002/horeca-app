import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/splash/splash_painter.dart';

/// Экран заставки (анимация галактики при запуске). CustomPainter и его
/// данные вынесены в splash_painter.dart, чтобы не раздувать этот файл.
///
/// Сотрудники открывают приложение много раз за смену — фиксированная пауза
/// на старте должна быть короткой (не декоративной 10-секундной анимацией,
/// как было раньше), плюс тап сразу пропускает её для тех, кто торопится.
class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSkip;
  const SplashScreen({super.key, this.onSkip});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rnd = Random(42);

  late List<Star> _stars;
  final List<Particle> _particles = [];
  final List<Shoot> _shoots = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _stars = List.generate(160, (i) => Star(
      x: _rnd.nextDouble(),
      y: _rnd.nextDouble(),
      r: 0.3 + _rnd.nextDouble() * 1.4,
      phase: _rnd.nextDouble() * pi * 2,
      speed: 0.4 + _rnd.nextDouble() * 1.2,
    ));

    _ctrl.forward();

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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSkip,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            // t — это "прошедшие секунды" для скоростей звёзд/частиц, а не
            // доля от 0 до 1: раньше анимация длилась 10 честных секунд,
            // поэтому _ctrl.value*10 совпадал с реальным временем. Теперь
            // контроллер короче — пересчитываем через его реальную
            // длительность, чтобы скорость движения не менялась.
            final totalSeconds = _ctrl.duration!.inMilliseconds / 1000;
            final t = _ctrl.value * totalSeconds;
            _updateParticles();
            _maybeShoot();
            return CustomPaint(
              painter: GalaxyPainter(
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
      _shoots.add(Shoot(
        x: _rnd.nextDouble() * 400,
        y: _rnd.nextDouble() * 150,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 1.0,
      ));
    }
  }
}
