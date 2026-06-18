import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class ThemeTab extends ConsumerWidget {
  const ThemeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final isDark = themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
      child: Column(
        children: [
          // Карточка с иконкой
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    // живая иконка логотипа
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _AkylIcon(key: ValueKey(themeMode), isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.translate('theme') ?? 'Тема',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      themeMode == ThemeMode.system
                          ? 'Системная тема'
                          : isDark
                              ? 'Тёмная тема включена'
                              : 'Светлая тема включена',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Кнопки выбора темы
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(ThemeMode.light),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: themeMode == ThemeMode.light
                          ? AppColors.orange.withOpacity(0.12)
                          : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                      border: Border.all(
                        color: themeMode == ThemeMode.light
                            ? AppColors.orange.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                        width: themeMode == ThemeMode.light ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            color: themeMode == ThemeMode.light
                                ? AppColors.orange
                                : AppColors.muted,
                            size: 28),
                        const SizedBox(height: 8),
                        Text('Светлая',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: themeMode == ThemeMode.light
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: themeMode == ThemeMode.light
                                  ? AppColors.orange
                                  : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(ThemeMode.system),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: themeMode == ThemeMode.system
                          ? AppColors.green.withOpacity(0.12)
                          : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                      border: Border.all(
                        color: themeMode == ThemeMode.system
                            ? AppColors.green.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                        width: themeMode == ThemeMode.system ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.brightness_auto_rounded,
                            color: themeMode == ThemeMode.system
                                ? AppColors.green
                                : AppColors.muted,
                            size: 28),
                        const SizedBox(height: 8),
                        Text('Авто',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: themeMode == ThemeMode.system
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: themeMode == ThemeMode.system
                                  ? AppColors.green
                                  : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: themeMode == ThemeMode.dark
                          ? AppColors.orange.withOpacity(0.12)
                          : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                      border: Border.all(
                        color: themeMode == ThemeMode.dark
                            ? AppColors.orange.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                        width: themeMode == ThemeMode.dark ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.nightlight_round,
                            color: themeMode == ThemeMode.dark
                                ? AppColors.orange
                                : AppColors.muted,
                            size: 28),
                        const SizedBox(height: 8),
                        Text('Тёмная',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: themeMode == ThemeMode.dark
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: themeMode == ThemeMode.dark
                                  ? AppColors.orange
                                  : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Живая анимированная иконка ────────────────────────────────────────────
class _AkylIcon extends StatefulWidget {
  final bool isDark;
  const _AkylIcon({super.key, required this.isDark});

  @override
  State<_AkylIcon> createState() => _AkylIconState();
}

class _AkylIconState extends State<_AkylIcon>
    with SingleTickerProviderStateMixin {
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
        painter: _IconPainter(
          t: _ctrl.value * 8,
          isDark: widget.isDark,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final double t;
  final bool isDark;
  const _IconPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final CX = W / 2, CY = H / 2;

    // фон иконки
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, W, H), const Radius.circular(22));
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.2,
          colors: isDark
              ? [const Color(0xFF1A1E2E), const Color(0xFF0D1128), const Color(0xFF060A18)]
              : [const Color(0xFFEEF2FF), const Color(0xFFDDE8FF), const Color(0xFFC8D8FF)],
        ).createShader(Rect.fromLTWH(0, 0, W, H)),
    );

    // орбиты
    final orbitPaint = Paint()
      ..color = (isDark ? const Color(0xFF8C5020) : const Color(0xFFB05A10))
          .withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final rot in [-0.52, 0.52]) {
      canvas.save();
      canvas.translate(CX, CY);
      canvas.rotate(rot);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: W * 0.82, height: H * 0.25),
          orbitPaint);
      canvas.restore();
    }

    // планеты
    for (int i = 0; i < 2; i++) {
      final rot = i == 0 ? -0.52 : 0.52;
      final ang = i == 0 ? t * 0.75 - 1.57 : -t * 0.6 + 3.14;
      final r = i == 0 ? 5.5 : 4.5;
      final px = cos(ang) * W * 0.41;
      final py = sin(ang) * H * 0.125;
      final wx = CX + px * cos(rot) - py * sin(rot);
      final wy = CY + px * sin(rot) + py * cos(rot);
      canvas.drawCircle(
        Offset(wx, wy),
        r,
        Paint()
          ..shader = RadialGradient(colors: const [
            Color(0xFFFFB067),
            Color(0xFFF5862E),
          ]).createShader(
              Rect.fromCircle(center: Offset(wx, wy), radius: r)),
      );
    }

    // буква A
    final tp = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          fontSize: W * 0.48,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas,
        Offset(CX - tp.width / 2, CY - tp.height / 2 + W * 0.02));
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.t != t || old.isDark != isDark;
}
