import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/splash/splash_painter.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/shared/widgets/spiral_mark.dart';

/// Экран заставки: фон палитры со звёздами (splash_painter.dart) и знак
/// «Спираль», который прорисовывается при запуске.
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
      backgroundColor: isDark ? AppColors.darkDeep : AppColors.lightBg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSkip,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => CustomPaint(
                  painter: SplashBackgroundPainter(
                    t: _ctrl.value * _ctrl.duration!.inMilliseconds / 1000,
                    isDark: isDark,
                    stars: _stars,
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.18),
              child: SpiralMark(
                size: 190,
                drawIn: true,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
