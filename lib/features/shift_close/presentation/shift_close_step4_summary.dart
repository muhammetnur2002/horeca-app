/// Шаг 4 экрана "Закрытие смены" — итог и отправка отчёта.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_format.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_revenue_ring.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_widgets.dart';

Widget buildShiftStep4({
  required bool isDark,
  required int totalSteps,
  required String currency,
  required List<DessertItem> desserts,
  required List<ManualWriteOff> manualWriteOffs,
  required Set<String> selectedStaff,
  required TextEditingController qrController,
  required TextEditingController cardController,
  required TextEditingController cashController,
  required TextEditingController morningCashController,
  required TextEditingController eveningCashController,
  required TextEditingController inkassController,
  required bool hasInkass,
  required double finalTotal,
  required double tomorrowCash,
  required VoidCallback onSubmit,
  double? previousRevenue,
}) {
  final qr = double.tryParse(qrController.text) ?? 0;
  final card = double.tryParse(cardController.text) ?? 0;
  final cash = double.tryParse(cashController.text) ?? 0;
  final change = previousRevenue == null || previousRevenue <= 0
      ? null
      : (finalTotal - previousRevenue) / previousRevenue * 100;
  final writeOffs = desserts.where((d) => d.writeOff > 0).toList();
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    StepHeader(step: 4, total: totalSteps, title: 'Итог смены'),
    const SizedBox(height: 16),
    Center(
      child: RevenueRing(
        qr: qr,
        card: card,
        cash: cash,
        amountText: '${shiftCloseFormatMoney(finalTotal)} $currency',
        caption: change == null
            ? shiftCloseFormattedDate()
            : '${change >= 0 ? '+' : ''}${change.round()}% к прошлой смене',
      ),
    ),
    const SizedBox(height: 14),
    GlassCard(
        isDark: isDark,
        child: Column(children: [
          SummaryRow(
              label: 'Сотрудники',
              value: selectedStaff.isEmpty ? '—' : selectedStaff.join(', '),
              isDark: isDark),
          SummaryRow(
              dotColor: PaymentColors.qr,
              label: 'QR-код',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(qrController.text) ?? 0)} $currency',
              isDark: isDark),
          SummaryRow(
              dotColor: PaymentColors.card,
              label: 'Банк. карта',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(cardController.text) ?? 0)} $currency',
              isDark: isDark),
          SummaryRow(
              dotColor: PaymentColors.cash,
              label: 'Наличные',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(cashController.text) ?? 0)} $currency',
              isDark: isDark),
          const ThinDivider(),
          SummaryRow(
              label: 'Касса Начало смены',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(morningCashController.text) ?? 0)} $currency',
              isDark: isDark),
          SummaryRow(
              label: 'Касса Конец смены',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(eveningCashController.text) ?? 0)} $currency',
              isDark: isDark),
          if (hasInkass)
            SummaryRow(
                label: 'Инкассация',
                value:
                    '${shiftCloseFormatMoney(double.tryParse(inkassController.text) ?? 0)} $currency',
                isDark: isDark),
          SummaryRow(
              label: 'Касса на завтра',
              value: '${shiftCloseFormatMoney(tomorrowCash)} $currency',
              isDark: isDark,
              highlight: true),
          if (writeOffs.isNotEmpty) ...[
            const ThinDivider(),
            ...writeOffs.map((d) => SummaryRow(
                label: '📦 Списание',
                value: '${d.name}: ${d.writeOff} шт',
                isDark: isDark,
                isWarning: true)),
          ],
          if (manualWriteOffs.isNotEmpty) ...[
            const ThinDivider(),
            ...manualWriteOffs.map((m) => SummaryRow(
                label: '📦 Списание',
                value: '${m.name}: ${m.quantity} ${m.unit}',
                isDark: isDark,
                isWarning: true)),
          ],
        ])),
    const SizedBox(height: 16),
    // Главное действие экрана — яркий градиент темы.
    GestureDetector(
      onTap: onSubmit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
              colors: [AppColors.orange, AppColors.greenLight]),
          boxShadow: [
            BoxShadow(
                color: AppColors.orange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const Text('Закрыть смену и отправить PDF',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ),
    ),
    const SizedBox(height: 16),
    const CardLabel(text: 'Или отправить в мессенджер'),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(
          child: ShareButton(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              isDark: isDark,
              onTap: onSubmit)),
      const SizedBox(width: 10),
      Expanded(
          child: ShareButton(
              icon: Icons.send_rounded,
              label: 'Telegram',
              color: const Color(0xFF2AABEE),
              isDark: isDark,
              onTap: onSubmit)),
    ]),
    const SizedBox(height: 16),
  ]);
}
