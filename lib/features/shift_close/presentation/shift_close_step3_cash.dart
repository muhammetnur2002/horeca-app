/// Шаг 3 экрана "Закрытие смены" — касса и инкассация.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_format.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_widgets.dart';

Widget buildShiftStep3({
  required StateSetter setState,
  required bool isDark,
  required int totalSteps,
  required String currency,
  required TextEditingController morningCashController,
  required TextEditingController eveningCashController,
  required TextEditingController inkassController,
  required bool hasInkass,
  required double tomorrowCash,
  required ValueChanged<bool> onHasInkassChanged,
}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    StepHeader(step: 3, total: totalSteps, title: 'Касса и инкассация'),
    const SizedBox(height: 16),
    GlassCard(
        isDark: isDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardLabel(text: 'Наличные в кассе'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: CashField(
                    label: 'Начало смены',
                    controller: morningCashController,
                    isDark: isDark,
                    currency: currency,
                    onChanged: (_) => setState(() {}))),
            const SizedBox(width: 10),
            Expanded(
                child: CashField(
                    label: 'Конец смены',
                    controller: eveningCashController,
                    isDark: isDark,
                    currency: currency,
                    onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 12),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.05 : 0.6),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Касса на следуюущую смену',
                        style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    Text('${shiftCloseFormatMoney(tomorrowCash)} $currency',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E))),
                  ])),
        ])),
    const SizedBox(height: 10),
    GlassCard(
        isDark: isDark,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Была инкассация?',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Switch(
                value: hasInkass,
                activeColor: AppColors.orange,
                onChanged: onHasInkassChanged),
          ]),
          if (hasInkass) ...[
            const SizedBox(height: 12),
            AmountField(
                label: 'Сумма инкассации',
                controller: inkassController,
                isDark: isDark,
                currency: currency,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 6),
            const Text('Остаток в кассе пересчитается автоматически',
                style: TextStyle(fontSize: 11, color: AppColors.orange)),
          ],
        ])),
    const SizedBox(height: 16),
  ]);
}
