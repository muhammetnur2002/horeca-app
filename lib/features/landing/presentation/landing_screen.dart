/// Лендинг: человек выбирает дверь — «Я сотрудник» или «Я владелец
/// заведения». Вёрстка по макету Figma «Akyl — две двери».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/landing/data/door_repository.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  static const _cream = Color(0xFFFFF7EE);
  static const _logoDark = Color(0xFFF1E9DD);
  static const _primary = Color(0xFFD8601A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final panel = isDark ? const Color(0xFF141B2B) : Colors.white;
    final line = isDark ? Colors.white.withOpacity(0.08) : const Color(0x1A1A1A2E);
    final door = ref.read(doorProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : _cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              children: [
                Text('Akyl',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: isDark ? _logoDark : AppColors.orange,
                    )),
                const SizedBox(height: 18),
                Text('Работа и заведение\nв одном месте',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28, height: 1.22, fontWeight: FontWeight.w800, color: text)),
                const SizedBox(height: 10),
                // Текст Grok 1 (docs/совместная-работа.md, PR #15).
                Text('Сотрудник ведёт профиль и отклики.
Владелец ведёт заявки, склад и смены.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? const Color(0xFFB8BFCC) : const Color(0xFF5A6070))),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                  child: Semantics(
                    label: 'Кафе: стойка, дверь с табличкой «Открыто», столик со стульями',
                    child: CustomPaint(painter: _CafePainter(isDark: isDark)),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => door.choose(AppDoor.staff),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('Я сотрудник'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => door.choose(AppDoor.venue),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: text,
                      side: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.24) : const Color(0x401A1A2E),
                          width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Я владелец заведения'),
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: line),
                  ),
                  child: IntrinsicHeight(
                    child: Row(children: [
                      _Perk(icon: Icons.verified_user_outlined, label: 'Удобно\nи надёжно', isDark: isDark),
                      VerticalDivider(width: 1, color: line),
                      _Perk(icon: Icons.schedule_rounded, label: 'Экономит\nвремя', isDark: isDark),
                      VerticalDivider(width: 1, color: line),
                      _Perk(icon: Icons.favorite_border_rounded, label: 'Для команды\nи бизнеса', isDark: isDark),
                    ]),
                  ),
                ),
              ],
            ),
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
  const _Perk({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(children: [
          Icon(icon, color: AppColors.orange, size: 24),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: isDark ? const Color(0xFFB8BFCC) : const Color(0xFF5A6070),
              )),
        ]),
      ),
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
    final base = stroke(isDark ? const Color(0xFF5C6F96) : const Color(0xFF8A7B6A));
    final accent = stroke(AppColors.orange);
    final leaf = stroke(const Color(0xFF5E8A6B));

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
