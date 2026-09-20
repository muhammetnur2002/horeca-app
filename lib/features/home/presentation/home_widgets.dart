/// Виджеты главного экрана: градиентный фон, баннер "товары заканчиваются",
/// приветствие и большая кнопка-плитка. Вынесены из home_screen.dart.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

class Background extends StatelessWidget {
  final bool isDark;
  const Background({super.key, required this.isDark});

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
        Positioned(
            top: -60,
            right: -60,
            child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(isDark ? 0.08 : 0.06)))),
        Positioned(
            bottom: 80,
            left: -40,
            child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green.withOpacity(isDark ? 0.06 : 0.05)))),
      ]),
    );
  }
}

/// Баннер "N товаров заканчивается" — показывается, когда есть товары
/// ниже минимального остатка.
class LowStockBanner extends StatelessWidget {
  final List<dynamic> items;
  final bool isDark;
  const LowStockBanner({super.key, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final itemNames = items.map((p) => p.name).take(2).join(', ');
    final itemWord = items.length == 1 ? 'товар заканчивается' : 'товара заканчиваются';
    final suffix = items.length > 2 ? '...' : '';
    final label = '${items.length} $itemWord: $itemNames$suffix';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.08),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E),
              ),
            )),
      ]),
    );
  }
}

/// "Доброе утро / Добрый день / Добрый вечер" + сегодняшняя дата.
class GreetingHeader extends StatelessWidget {
  final bool isDark;
  const GreetingHeader({super.key, required this.isDark});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? AppColors.muted : const Color(0xFF6B7280);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_greeting(),
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(_formattedDate(), style: TextStyle(fontSize: 14, color: subColor)),
    ]);
  }
}

/// Большая кнопка-плитка ("Сделать заявку", "Закрытие смены", ...).
class GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isPrimary;
  final bool isDark;
  final Color? accentColor;
  final VoidCallback onTap;

  const GlassButton({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [accent.withOpacity(isDark ? 0.25 : 0.18), accent.withOpacity(isDark ? 0.10 : 0.08)]
                  : [
                      Colors.white.withOpacity(isDark ? 0.08 : 0.55),
                      Colors.white.withOpacity(isDark ? 0.04 : 0.35)
                    ],
            ),
            border: Border.all(
              color: isPrimary
                  ? accent.withOpacity(0.35)
                  : Colors.white.withOpacity(isDark ? 0.12 : 0.80),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(isPrimary ? 0.12 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: accent, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: TextStyle(
                          fontSize: 13,
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
