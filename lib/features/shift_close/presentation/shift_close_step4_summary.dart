/// Шаг 4 экрана "Закрытие смены" — итог и отправка отчёта.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_format.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';
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
}) {
  final writeOffs = desserts.where((d) => d.writeOff > 0).toList();
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    StepHeader(step: 4, total: totalSteps, title: 'Итог смены'),
    const SizedBox(height: 16),
    GlassCard(
        isDark: isDark,
        accentColor: AppColors.green,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ИТОГОВАЯ ВЫРУЧКА',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text('${shiftCloseFormatMoney(finalTotal)} $currency',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                  letterSpacing: -1)),
          Text(shiftCloseFormattedDate(),
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
    const SizedBox(height: 10),
    GlassCard(
        isDark: isDark,
        child: Column(children: [
          SummaryRow(
              label: 'Сотрудники',
              value: selectedStaff.isEmpty ? '—' : selectedStaff.join(', '),
              isDark: isDark),
          SummaryRow(
              label: 'QR-код',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(qrController.text) ?? 0)} $currency',
              isDark: isDark),
          SummaryRow(
              label: 'Банк. карта',
              value:
                  '${shiftCloseFormatMoney(double.tryParse(cardController.text) ?? 0)} $currency',
              isDark: isDark),
          SummaryRow(
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
    const CardLabel(text: 'Отправить отчёт'),
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
    const SizedBox(height: 10),
    ShareButton(
        icon: Icons.picture_as_pdf_rounded,
        label: 'Скачать PDF',
        color: AppColors.orange,
        isDark: isDark,
        onTap: onSubmit,
        fullWidth: true),
    const SizedBox(height: 16),
  ]);
}
