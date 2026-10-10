/// Лендинг: человек выбирает дверь — «Я сотрудник» или «Я владелец
/// заведения». Вёрстка по макету «Akyl — две двери», строго три цвета:
/// оранжевый, чёрный, кремовый.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/landing/data/door_repository.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.cream : AppColors.black;
    final sub = isDark ? AppColors.muted : const Color(0xFF5E5D5B);
    final line = isDark ? AppColors.cream.withOpacity(0.12) : AppColors.black.withOpacity(0.10);
    final door = ref.read(doorProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              children: [
                Text('Akyl',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: isDark ? AppColors.cream : AppColors.orange,
                    )),
                const SizedBox(height: 22),
                Text('Работа и заведение\nв одном месте',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, color: text)),
                const SizedBox(height: 10),
                // Текст Grok 1 (docs/совместная-работа.md, PR #15).
                Text('Сотрудник ведёт профиль и отклики.\nВладелец ведёт заявки, склад и смены.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4, color: sub)),
                const SizedBox(height: 18),
                Container(
                  height: 210,
                  decoration: isDark
                      ? BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(18))
                      : null,
                  child: Semantics(
                    label: 'Кафе: стойка, лампа, дверь с табличкой «Открыто», столик со стульями',
                    child: CustomPaint(painter: _CafePainter(isDark: isDark)),
                  ),
                ),
                const SizedBox(height: 22),
                _DoorButton(
                  label: 'Я сотрудник',
                  icon: Icons.person_outline_rounded,
                  primary: true,
                  isDark: isDark,
                  onTap: () => door.choose(AppDoor.staff),
                ),
                const SizedBox(height: 12),
                _DoorButton(
                  label: 'Я владелец заведения',
                  icon: Icons.storefront_outlined,
                  primary: false,
                  isDark: isDark,
                  onTap: () => door.choose(AppDoor.venue),
                ),
                const SizedBox(height: 26),
                if (isDark)
                  IntrinsicHeight(
                    child: Row(children: [
                      _Perk(icon: Icons.verified_user_outlined, label: 'Удобно\nи надёжно', isDark: isDark),
                      VerticalDivider(width: 1, color: line),
                      _Perk(icon: Icons.schedule_rounded, label: 'Экономит\nвремя', isDark: isDark),
                      VerticalDivider(width: 1, color: line),
                      _Perk(icon: Icons.favorite_border_rounded, label: 'Для команды\nи бизнеса', isDark: isDark),
                    ]),
                  )
                else
                  IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final perk in const [
                        (Icons.verified_user_outlined, 'Удобно\nи надёжно'),
                        (Icons.schedule_rounded, 'Экономит\nвремя'),
                        (Icons.favorite_border_rounded, 'Для команды\nи бизнеса'),
                      ]) ...[
                        if (perk.$1 != Icons.verified_user_outlined) const SizedBox(width: 10),
                        _Perk(icon: perk.$1, label: perk.$2, isDark: isDark, boxed: true),
                      ],
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка двери: капсула. Главная — оранжевая с чёрным текстом (белый на
/// #FF6A00 читается плохо), вторая — контурная.
class _DoorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final bool isDark;
  final VoidCallback onTap;
  const _DoorButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.black : (isDark ? AppColors.cream : AppColors.black);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: primary ? AppColors.orange : Colors.transparent,
        shape: StadiumBorder(
          side: primary
              ? BorderSide.none
              : BorderSide(
                  color: isDark ? AppColors.cream.withOpacity(0.35) : AppColors.black.withOpacity(0.30),
                  width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: Row(children: [
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary ? AppColors.black : (isDark ? AppColors.cream : AppColors.black).withOpacity(0.08),
                ),
                child: Icon(icon, size: 22, color: primary ? AppColors.orange : fg),
              ),
              Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
              ),
              Icon(Icons.arrow_forward_rounded, color: fg),
              const SizedBox(width: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool boxed;
  const _Perk({required this.icon, required this.label, required this.isDark, this.boxed = false});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(children: [
        Icon(icon, color: isDark ? AppColors.cream : AppColors.orange, size: 28),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: isDark ? AppColors.cream.withOpacity(0.8) : AppColors.black,
            )),
      ]),
    );
    return Expanded(
      child: boxed
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.black.withOpacity(0.10)),
              ),
              child: content,
            )
          : content,
    );
  }
}

/// Линейная картинка кафе: стойка, лампа, дверь «Открыто», столик, растение.
class _CafePainter extends CustomPainter {
  final bool isDark;
  const _CafePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const w = 330.0, h = 190.0;
    final scale = (size.width / w < size.height / h ? size.width / w : size.height / h);
    canvas.translate((size.width - w * scale) / 2, size.height - h * scale);
    canvas.scale(scale);

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final base = stroke(isDark ? AppColors.cream.withOpacity(0.45) : AppColors.black.withOpacity(0.75));
    final accent = stroke(AppColors.orange);
    final leaf = stroke(AppColors.orange.withOpacity(0.7));

    void path(List<Offset> points, Paint paint) {
      final p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final o in points.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p, paint);
    }

    path(const [Offset(10, 176), Offset(320, 176)], base);
    // Стойка с посудой.
    path(const [Offset(28, 176), Offset(28, 114), Offset(124, 114), Offset(124, 176)], base);
    path(const [Offset(22, 114), Offset(130, 114)], base);
    path(const [Offset(40, 114), Offset(40, 104), Offset(54, 104), Offset(54, 114)], base);
    path(const [Offset(62, 114), Offset(62, 98), Offset(72, 98), Offset(72, 114)], base);
    path(const [Offset(80, 114), Offset(80, 106), Offset(92, 106), Offset(92, 114)], base);
    // Лампа.
    path(const [Offset(76, 20), Offset(76, 48)], base);
    path(const [Offset(62, 48), Offset(90, 48), Offset(86, 58), Offset(66, 58), Offset(62, 48)], base);
    path(const [Offset(76, 58), Offset(76, 62)], accent);
    // Дверь с табличкой.
    path(const [Offset(150, 176), Offset(150, 54), Offset(206, 54), Offset(206, 176)], base);
    path(const [Offset(158, 176), Offset(158, 64), Offset(198, 64), Offset(198, 176)], base);
    canvas.drawCircle(const Offset(191, 122), 2.5, base);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(164, 80, 28, 14), const Radius.circular(2)), accent);
    path(const [Offset(169, 87), Offset(187, 87)], accent);
    // Полка.
    path(const [Offset(226, 30), Offset(296, 30)], base);
    path(const [Offset(236, 30), Offset(236, 46)], base);
    path(const [Offset(286, 30), Offset(286, 46)], base);
    // Столик, стулья и чайник.
    path(const [Offset(232, 128), Offset(294, 128)], base);
    path(const [Offset(263, 128), Offset(263, 176)], base);
    path(const [Offset(248, 176), Offset(278, 176)], base);
    path(const [Offset(226, 176), Offset(226, 140), Offset(236, 140), Offset(236, 154)], base);
    path(const [Offset(300, 176), Offset(300, 140), Offset(290, 140), Offset(290, 154)], base);
    canvas.drawArc(const Rect.fromLTWH(250, 98, 26, 28), 3.14159, 3.14159, false, base);
    path(const [Offset(250, 112), Offset(276, 112)], base);
    // Растение.
    final plant = Path()
      ..moveTo(304, 176)
      ..quadraticBezierTo(306, 146, 320, 136);
    canvas.drawPath(plant, leaf);
  }

  @override
  bool shouldRepaint(_CafePainter old) => old.isDark != isDark;
}
