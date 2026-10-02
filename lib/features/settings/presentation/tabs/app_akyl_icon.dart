/// Живая иконка "Akyl" на вкладке "Приложение": знак «Спираль» на плитке
/// цвета текущей палитры (как иконка приложения на рабочем столе).
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/shared/widgets/spiral_mark.dart';

class AkylIcon extends StatelessWidget {
  final bool isDark;
  const AkylIcon({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.current;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(c.darkScreen, c.primary, 0.22)!,
            c.darkScreen,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: c.primary.withOpacity(isDark ? 0.35 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const SpiralMark(size: 88, drawIn: true, isDark: true),
    );
  }
}
