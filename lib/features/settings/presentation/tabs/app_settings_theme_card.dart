/// Карточка "Akyl" + переключатель темы (светлая/авто/тёмная) на вкладке
/// "Приложение". Вынесена из app_settings_tab.dart.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_akyl_icon.dart';

class AppThemeCard extends StatelessWidget {
  final ThemeMode themeMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onSetThemeMode;

  const AppThemeCard({
    super.key,
    required this.themeMode,
    required this.isDark,
    required this.onSetThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
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
      ],
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
