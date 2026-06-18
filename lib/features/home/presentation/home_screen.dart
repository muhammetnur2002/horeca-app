import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _AkylLogoTitle(isDark: isDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _Background(isDark: isDark)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _GreetingHeader(isDark: isDark),
                  const SizedBox(height: 20),
                  _GlassButton(
                    icon: Icons.assignment_outlined,
                    label: l10n.makeRequest,
                    sublabel: 'Кухня, бар, склад, зал',
                    isPrimary: true,
                    isDark: isDark,
                    onTap: () => context.push('/request'),
                  ),
                  const SizedBox(height: 12),
                  _GlassButton(
                    icon: Icons.inventory_2_outlined,
                    label: l10n.inventory,
                    sublabel: 'Подсчёт остатков',
                    isPrimary: false,
                    isDark: isDark,
                    onTap: () => context.push('/inventory'),
                  ),
                  const SizedBox(height: 12),
                  _GlassButton(
                    icon: Icons.nights_stay_outlined,
                    label: 'Закрытие смены',
                    sublabel: 'Отчёт и PDF',
                    isPrimary: false,
                    isDark: isDark,
                    accentColor: AppColors.green,
                    onTap: () => context.push('/shift-close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Лого в AppBar ────────────────────────────────────────────────────────────
class _AkylLogoTitle extends StatefulWidget {
  final bool isDark;
  const _AkylLogoTitle({required this.isDark});
  @override
  State<_AkylLogoTitle> createState() => _AkylLogoTitleState();
}

class _AkylLogoTitleState extends State<_AkylLogoTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))..repeat();
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
            painter: _MiniLogoPainter(
                t: _ctrl.value * 8, isDark: widget.isDark),
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
    final W = size.width, H = size.height;
    final CX = W / 2, CY = H / 2;

    // фон
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, W, H), Radius.circular(W * 0.22));
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(0, 0, W, H), Paint()
      ..shader = RadialGradient(colors: isDark
          ? [const Color(0xFF1A1E2E), const Color(0xFF060A18)]
          : [const Color(0xFFEEF2FF), const Color(0xFFC8D8FF)])
          .createShader(Rect.fromLTWH(0, 0, W, H)));

    // орбиты
    final orbitPaint = Paint()
      ..color = (isDark ? const Color(0xFF8C5020) : const Color(0xFFB05A10)).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final rot in [-0.52, 0.52]) {
      canvas.save();
      canvas.translate(CX, CY);
      canvas.rotate(rot);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: W * 0.88, height: H * 0.28),
          orbitPaint);
      canvas.restore();
    }

    // планеты
    for (int i = 0; i < 2; i++) {
      final rot = i == 0 ? -0.52 : 0.52;
      final ang = i == 0 ? t * 0.75 - pi * 0.5 : -t * 0.6 + pi;
      final r = i == 0 ? W * 0.11 : W * 0.09;
      final px = cos(ang) * W * 0.44;
      final py = sin(ang) * H * 0.14;
      final wx = CX + px * cos(rot) - py * sin(rot);
      final wy = CY + px * sin(rot) + py * cos(rot);
      canvas.drawCircle(Offset(wx, wy), r, Paint()
        ..shader = RadialGradient(
            colors: const [Color(0xFFFFB067), Color(0xFFF5862E)])
            .createShader(Rect.fromCircle(center: Offset(wx, wy), radius: r)));
    }

    // буква A
    final tp = TextPainter(
      text: TextSpan(text: 'A', style: TextStyle(
        fontSize: W * 0.5, fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
      )),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(CX - tp.width / 2, CY - tp.height / 2 + W * 0.02));
  }

  @override
  bool shouldRepaint(_MiniLogoPainter old) =>
      old.t != t || old.isDark != isDark;
}

// ── Фон ─────────────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final bool isDark;
  const _Background({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
              : const [Color(0xFFE8F4FD), Color(0xFFF0F8FF), Color(0xFFE8EAF6)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -60, right: -60,
            child: Container(width: 220, height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(isDark ? 0.08 : 0.06)))),
        Positioned(bottom: 80, left: -40,
            child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.green.withOpacity(isDark ? 0.06 : 0.05)))),
      ]),
    );
  }
}

// ── Приветствие ──────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final bool isDark;
  const _GreetingHeader({required this.isDark});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['','января','февраля','марта','апреля','мая','июня',
        'июля','августа','сентября','октября','ноября','декабря'];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? AppColors.muted : const Color(0xFF6B7280);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_greeting(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
          color: textColor, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(_formattedDate(), style: TextStyle(fontSize: 14, color: subColor)),
    ]);
  }
}

// ── Кнопка ───────────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isPrimary;
  final bool isDark;
  final Color? accentColor;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon, required this.label, required this.sublabel,
    required this.isPrimary, required this.isDark, required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.orange;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isPrimary
                    ? [accent.withOpacity(isDark ? 0.25 : 0.18), accent.withOpacity(isDark ? 0.10 : 0.08)]
                    : [Colors.white.withOpacity(isDark ? 0.08 : 0.55), Colors.white.withOpacity(isDark ? 0.04 : 0.35)],
              ),
              border: Border.all(
                color: isPrimary ? accent.withOpacity(0.35) : Colors.white.withOpacity(isDark ? 0.12 : 0.80),
              ),
              boxShadow: [BoxShadow(
                color: accent.withOpacity(isPrimary ? 0.12 : 0.04),
                blurRadius: 20, offset: const Offset(0, 4),
              )],
            ),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: accent, size: 24)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(sublabel, style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF6B7280))),
              ])),
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.2),
                  size: 20),
            ]),
          ),
        ),
      );
  }
}
