/// Продолжение мелких виджетов экрана "Закрытие смены": поля суммы, строка
/// итога, кнопка "поделиться", тонкий разделитель, диалог подтверждения
/// закрытия смены. Вынесены из shift_close_widgets.dart, чтобы уложиться
/// в лимит строк на файл — реэкспортируются оттуда, так что импортировать
/// этот файл отдельно не нужно.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horeca_app/app/app.dart';

class AmountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final String currency;
  const AmountField({
    super.key,
    required this.label,
    required this.controller,
    required this.isDark,
    this.hint,
    this.onChanged,
    this.currency = '₸',
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF1A1A2E)))),
        SizedBox(
            width: 120,
            child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                    hintText: hint ?? '0',
                    hintStyle:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                    suffixText: currency,
                    suffixStyle:
                        const TextStyle(fontSize: 13, color: AppColors.muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero))),
      ]);
}

class CashField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String>? onChanged;
  final String currency;
  const CashField({
    super.key,
    required this.label,
    required this.controller,
    required this.isDark,
    this.onChanged,
    this.currency = '₸',
  });

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                suffixText: currency,
                hintText: '0',
                hintStyle:
                    const TextStyle(fontSize: 15, color: AppColors.muted),
                suffixStyle:
                    const TextStyle(color: AppColors.muted, fontSize: 13))),
      ]));
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;
  final bool isWarning;
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                    color: isWarning
                        ? Colors.redAccent
                        : highlight
                            ? AppColors.orange
                            : isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E)))),
      ]));
}

class ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool fullWidth;
  const ShareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ])));
}

class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withOpacity(0.1));
}

class ConfirmCloseShiftDialog extends StatelessWidget {
  const ConfirmCloseShiftDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Закрыть смену?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
            'Будет сформирован PDF-отчёт. Вы сможете отправить его через WhatsApp или Telegram.',
            style: TextStyle(color: AppColors.muted, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена',
                  style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Закрыть и PDF')),
        ]);
  }
}
