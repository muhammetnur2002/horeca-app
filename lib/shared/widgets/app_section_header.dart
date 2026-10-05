import 'package:flutter/material.dart';
import 'package:horeca_app/app/design/tokens.dart';

/// Заголовок группы внутри экрана.
///
/// Отдельный виджет нужен не ради экономии строк, а ради одинакового
/// ритма: когда каждый экран задаёт свой размер и свой отступ, список
/// разделов читается как набор случайных надписей.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;

  /// Кнопка или счётчик справа — например «Добавить» или «12 шт».
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: palette.textMuted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
