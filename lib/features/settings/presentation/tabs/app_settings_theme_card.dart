/// Выбор режима (тёмная/светлая/авто) на вкладке
/// "Приложение" и выбор одной из 5 палитр оформления.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/shared/widgets/orbit_kit.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrbitSectionLabel('Режим'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (mode, label) in [
            (ThemeMode.dark, 'Тёмная'),
            (ThemeMode.light, 'Светлая'),
            (ThemeMode.system, 'Авто'),
          ])
            OrbitChip(
              label: label,
              selected: themeMode == mode,
              onTap: () => onSetThemeMode(mode),
            ),
        ]),
        const SizedBox(height: 16),
        const OrbitSectionLabel('Оформление'),
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
