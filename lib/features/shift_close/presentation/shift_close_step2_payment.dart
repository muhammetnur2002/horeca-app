/// Шаг 2 экрана "Закрытие смены" — способы оплаты.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_format.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_widgets.dart';

Widget buildShiftStep2({
  required StateSetter setState,
  required bool isDark,
  required int totalSteps,
  required String currency,
  required TextEditingController qrController,
  required TextEditingController cardController,
  required TextEditingController cashController,
  required TextEditingController manualController,
  required double autoTotal,
}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    StepHeader(step: 2, total: totalSteps, title: 'Способы оплаты'),
    const SizedBox(height: 16),
    PaymentRow(
        icon: Icons.qr_code_rounded,
        label: 'QR-код',
        hint: 'СБП.',
        controller: qrController,
        color: AppColors.green,
        isDark: isDark,
        currency: currency,
        onChanged: (_) => setState(() {})),
    const SizedBox(height: 10),
    PaymentRow(
        icon: Icons.credit_card_rounded,
        label: 'Банковская карта',
        hint: 'Сбербанк, Т-банк',
        controller: cardController,
        color: const Color(0xFF378ADD),
        isDark: isDark,
        currency: currency,
        onChanged: (_) => setState(() {})),
    const SizedBox(height: 10),
    PaymentRow(
        icon: Icons.payments_outlined,
        label: 'Наличные',
        hint: 'Принято за смену',
        controller: cashController,
        color: AppColors.orange,
        isDark: isDark,
        currency: currency,
        onChanged: (_) => setState(() {})),
    const SizedBox(height: 16),
    GlassCard(
        isDark: isDark,
        accentColor: AppColors.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Итоговая выручка (авто)',
              style: TextStyle(fontSize: 11, color: AppColors.green)),
          const SizedBox(height: 4),
          Text('${shiftCloseFormatMoney(autoTotal)} $currency',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green)),
          const SizedBox(height: 2),
          const Text('QR + карта + наличные',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
    const SizedBox(height: 10),
    GlassCard(
        isDark: isDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardLabel(text: 'Скорректировать вручную (необязательно)'),
          const SizedBox(height: 10),
          AmountField(
              label: 'Итоговая выручка',
              controller: manualController,
              isDark: isDark,
              hint: shiftCloseFormatMoney(autoTotal),
              currency: currency,
              onChanged: (_) => setState(() {})),
        ])),
    const SizedBox(height: 16),
  ]);
}
