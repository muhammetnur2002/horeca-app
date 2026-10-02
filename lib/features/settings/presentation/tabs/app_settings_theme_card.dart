/// Карточка "Akyl" + переключатель темы (светлая/авто/тёмная) на вкладке
/// "Приложение" и выбор одной из 5 палитр оформления.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_akyl_icon.dart';

class AppThemeCard extends StatelessWidget {
  final ThemeMode themeMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onSetThemeMode;
  final AkylPalette palette;
  final ValueChanged<AkylPalette> onSetPalette;

  const AppThemeCard({
    super.key,
    required this.themeMode,
    required this.isDark,
    required this.onSetThemeMode,
    required this.palette,
    required this.onSetPalette,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.ink;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: AkylIcon(key: ValueKey(themeMode), isDark: isDark),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Akyl',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
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
        Row(
          children: [
            Expanded(
                child: _ThemeOption(
              icon: Icons.wb_sunny_rounded,
              label: 'Светлая',
              selected: themeMode == ThemeMode.light,
              accent: AppColors.orange,
              isDark: isDark,
              onTap: () => onSetThemeMode(ThemeMode.light),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _ThemeOption(
              icon: Icons.brightness_auto_rounded,
              label: 'Авто',
              selected: themeMode == ThemeMode.system,
              accent: AppColors.green,
              isDark: isDark,
              onTap: () => onSetThemeMode(ThemeMode.system),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _ThemeOption(
              icon: Icons.nightlight_round,
              label: 'Тёмная',
              selected: themeMode == ThemeMode.dark,
              accent: AppColors.orange,
              isDark: isDark,
              onTap: () => onSetThemeMode(ThemeMode.dark),
            )),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Оформление',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AkylPalette.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = AkylPalette.values[i];
              return _PaletteOption(
                palette: p,
                selected: p == palette,
                isDark: isDark,
                textColor: textColor,
                onTap: () => onSetPalette(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Плитка выбора палитры: превью фона темы с тремя акцентами и название.
class _PaletteOption extends StatelessWidget {
  final AkylPalette palette;
  final bool selected;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  const _PaletteOption({
    required this.palette,
    required this.selected,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AkylColors.of(palette);
    final screen = isDark ? c.darkScreen : c.lightScreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(isDark ? 0.04 : 0.4),
          border: Border.all(
            color: selected ? c.primary : Colors.white.withOpacity(0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [screen, Color.lerp(screen, c.primary, 0.35)!],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final col in [c.primary, c.secondary, c.tertiary])
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration:
                          BoxDecoration(color: col, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              palette.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? textColor : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? accent.withOpacity(0.12)
              : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
          border: Border.all(
            color: selected ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? accent : AppColors.muted, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? accent : AppColors.muted,
                )),
          ],
        ),
      ),
    );
  }
}
