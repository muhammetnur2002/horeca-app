import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const AnimatedSplashScreen({super.key, required this.nextScreen});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _progressFade;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Логотип: появляется и увеличивается
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Название: выезжает снизу
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // Подпись
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    // Индикатор загрузки
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );

    // Пульс иконки
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // ── Фон ───────────────────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F1629),
                    Color(0xFF1A1040),
                    Color(0xFF0D1F35),
                  ],
                ),
              ),
            ),
          ),

          // Декоративные круги
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withOpacity(0.06),
              ),
            ),
          ),

          // ── Основной контент ──────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Логотип
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Transform.scale(
                            scale: _pulse.value,
                            child: _LogoIcon(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Название
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'Akyl',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Подпись
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: const Text(
                        'Система управления HoReCa',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Индикатор загрузки
                    FadeTransition(
                      opacity: _progressFade,
                      child: _LoadingDots(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Иконка логотипа ──────────────────────────────────────────────────────────
class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.orange.withOpacity(0.3),
                AppColors.orange.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: AppColors.orange.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            size: 52,
            color: AppColors.orange,
          ),
        ),
      ),
    );
  }
}

// ── Анимированные точки загрузки ─────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final progress = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (1 - (progress * 2 - 1).abs()))
                .clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
