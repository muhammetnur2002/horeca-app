import 'package:flutter/material.dart';
import 'package:horeca_app/app/design/tokens.dart';

/// Экран или блок без данных.
///
/// Пустое место — самый частый момент, когда человек не понимает, что
/// делать дальше. Поэтому здесь не просто «Нет данных», а три части:
/// что произошло, почему так и что нажать. Последнее не обязательно,
/// но если действие есть — кнопка должна быть прямо здесь, а не в углу
/// экрана, куда ещё надо догадаться посмотреть.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;

  /// Короткая строка о том, что здесь пусто. Без точки в конце.
  final String title;

  /// Почему пусто и что с этим делать. Одно-два предложения.
  final String? description;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: palette.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: palette.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(220, kMinTapTarget),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
