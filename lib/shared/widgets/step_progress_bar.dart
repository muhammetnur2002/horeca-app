/// Компактный индикатор прогресса для многошаговых визардов (заявка,
/// инвентаризация) — точки-шаги с соединяющей линией. Даёт сотруднику понять,
/// сколько шагов ещё осталось, не отвлекая местом под подписи (в отличие от
/// ShiftStepperIndicator, у которого есть текстовые лейблы шагов).
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

class StepProgressBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Size get preferredSize => const Size.fromHeight(20);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final segmentDone = (i ~/ 2) < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: segmentDone ? AppColors.orange : trackColor,
                ),
              ),
            );
          }
          final di = i ~/ 2;
          final isDone = di < currentStep;
          final isActive = di == currentStep;
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone || isActive ? AppColors.orange : trackColor,
            ),
          );
        }),
      ),
    );
  }
}
