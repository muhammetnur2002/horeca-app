/// Индикатор шагов и нижняя панель навигации экрана "Закрытие смены".
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

/// Кружки-шаги вверху экрана ("Смена" → "Оплата" → "Касса" → "Итог").
class ShiftStepperIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isDark;
  final ValueChanged<int> onStepTap;
  static const _labels = ['Смена', 'Оплата', 'Касса', 'Итог'];

  const ShiftStepperIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
              child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: (i ~/ 2) < currentStep
                          ? AppColors.orange
                          : Colors.white.withOpacity(isDark ? 0.1 : 0.0))));
        }
        final di = i ~/ 2;
        final isDone = di < currentStep;
        final isActive = di == currentStep;
        return GestureDetector(
          onTap: () {
            if (di <= currentStep) onStepTap(di);
          },
          child: Column(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.green.withOpacity(0.2)
                        : isActive
                            ? AppColors.orange
                            : Colors.white.withOpacity(isDark ? 0.08 : 0.4),
                    border: Border.all(
                        color: isDone
                            ? AppColors.green
                            : isActive
                                ? AppColors.orange
                                : Colors.white.withOpacity(0.15),
                        width: 1.5)),
                child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.green)
                        : Text('${di + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.muted)))),
            const SizedBox(height: 4),
            Text(_labels[di],
                style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.orange : AppColors.muted,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal)),
          ]),
        );
      })),
    );
  }
}

/// Кнопки "Назад" / "Далее" / "Закрыть смену" внизу экрана.
class ShiftBottomBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const ShiftBottomBar({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.isDark,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          border: Border(
              top: BorderSide(
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.0)))),
      child: Row(children: [
        if (step > 0) ...[
          Expanded(
              child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      foregroundColor: AppColors.muted),
                  child: const Text('Назад'))),
          const SizedBox(width: 12),
        ],
        Expanded(
            flex: 2,
            child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor:
                        isLast ? AppColors.green : AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                child: Text(isLast ? '✓ Закрыть смену' : 'Далее →',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}
