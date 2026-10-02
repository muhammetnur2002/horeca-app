/// Мини-лого "Akyl" в AppBar главного экрана — знак «Спираль» на плитке
/// цвета текущей палитры.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/shared/widgets/spiral_mark.dart';

class AkylLogoTitle extends StatelessWidget {
  final bool isDark;
  const AkylLogoTitle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.current;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(c.darkScreen, c.primary, 0.22)!, c.darkScreen],
            ),
          ),
          alignment: Alignment.center,
          child: const SpiralMark(size: 34, isDark: true),
        ),
      ],
    );
  }
}
