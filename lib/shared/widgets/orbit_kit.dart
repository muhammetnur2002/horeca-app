/// Общие элементы оформления «Орбита» по макету: подпись раздела
/// моноширинным капсом, стеклянная группа строк с разделителями, строка
/// списка (иконка, заголовок, подпись, хвост) и кнопки действий.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

/// «ТЕМА», «КТО РАБОТАЛ» — подпись раздела.
class OrbitSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const OrbitSectionLabel(this.text,
      {super.key, this.padding = const EdgeInsets.fromLTRB(4, 4, 4, 8)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 10.5,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: AppColors.muted)),
    );
  }
}

/// Стеклянная карточка со строками, разделёнными тонкой линией.
class OrbitGroup extends StatelessWidget {
  final List<Widget> children;
  const OrbitGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: (isDark ? Colors.white : AppColors.ink).withOpacity(0.07),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(isDark ? 0.07 : 0.65),
            border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.12 : 0.9)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) divider,
                children[i],
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Строка списка: иконка в цветной плитке, заголовок, подпись и хвост
/// (по умолчанию — шеврон, если строка нажимается).
class OrbitRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool monoSubtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const OrbitRow({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.subtitle,
    this.monoSubtitle = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = iconColor ?? AppColors.orange;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.withOpacity(isDark ? 0.18 : 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: c, size: 19),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: monoSubtitle ? AppFonts.mono : null,
                          fontFamilyFallback: AppFonts.fallback,
                          fontSize: monoSubtitle ? 11 : 12.5,
                          color: AppColors.muted)),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white54 : AppColors.inkSoft),
        ]),
      ),
    );
  }
}

/// Чип выбора: выбранный — сплошной светлый (в тёмной теме) или тёмный.
class OrbitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const OrbitChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? (isDark ? Colors.white : AppColors.ink)
        : Colors.white.withOpacity(isDark ? 0.06 : 0.6);
    final fg = selected
        ? (isDark ? AppColors.ink : Colors.white)
        : (isDark ? Colors.white70 : AppColors.inkSoft);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withOpacity(isDark ? 0.14 : 0.9)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg)),
      ),
    );
  }
}

/// Главная кнопка экрана — градиент темы.
class OrbitPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const OrbitPrimaryButton(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: [AppColors.orange, AppColors.greenLight]),
            boxShadow: [
              BoxShadow(
                  color: AppColors.orange.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Второстепенная кнопка — матовое стекло.
class OrbitGlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const OrbitGlassButton(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : AppColors.ink;
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.7),
            border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.14 : 0.95)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
