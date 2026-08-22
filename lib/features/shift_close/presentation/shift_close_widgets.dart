/// Общие мелкие виджеты экрана "Закрытие смены" (карточки, поля, кнопки).
/// Вынесены из shift_close_screen.dart — каждый виджет самодостаточен
/// и не зависит от состояния экрана. Продолжение (поля суммы, итоговая
/// строка, кнопка "поделиться", диалог подтверждения) — в
/// shift_close_widgets_extra.dart, реэкспортируется отсюда, чтобы не
/// менять импорты в остальных файлах.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/shared/widgets/quantity_stepper.dart';

export 'shift_close_widgets_extra.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? accentColor;
  const GlassCard(
      {super.key, required this.child, required this.isDark, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final a = accentColor;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: a != null
                ? a.withOpacity(isDark ? 0.08 : 0.05)
                : Colors.white.withOpacity(isDark ? 0.08 : 0.6),
            border: Border.all(
                color: a != null
                    ? a.withOpacity(0.25)
                    : Colors.white.withOpacity(isDark ? 0.12 : 0.8))),
        child: child);
  }
}

class CardLabel extends StatelessWidget {
  final String text;
  const CardLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 0.6));
}

class StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  const StepHeader(
      {super.key, required this.step, required this.total, required this.title});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Шаг $step из $total',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.orange,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1A2E))),
      ]);
}

class DessertRow extends StatelessWidget {
  final String name;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final bool isWriteOff;
  const DessertRow({
    super.key,
    required this.name,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.isWriteOff = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(name,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withOpacity(0.85)
                        : const Color(0xFF1A1A2E)))),
        QuantityStepper(
          value: value.toDouble(),
          unit: '',
          isDark: isDark,
          productName: name,
          allowDecimal: false,
          onChanged: (v) => onChanged(v.round()),
        ),
      ]));
}

class QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const QtyBtn(
      {super.key, required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.3))),
          child: Icon(icon,
              size: 16,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E))));
}

class PaymentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final Color color;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final String currency;
  const PaymentRow({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.color,
    required this.isDark,
    required this.onChanged,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E))),
                      Text(hint,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ])),
                SizedBox(
                    width: 110,
                    child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: onChanged,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E)),
                        decoration: InputDecoration(
                            suffixText: currency,
                            hintText: '0',
                            hintStyle: const TextStyle(
                                fontSize: 15, color: AppColors.muted),
                            suffixStyle: const TextStyle(
                                fontSize: 13, color: AppColors.muted),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero))),
              ]))));
}

