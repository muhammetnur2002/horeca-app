/// Мелкие виджеты экрана "Аналитика": пустое состояние, карточки
/// вчерашней смены, чипы периода, строка
/// списания. Вынесены из analytics_screen.dart, чтобы не раздувать его
/// build().
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/core/money.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_revenue_ring.dart';

class EmptyState extends StatelessWidget {
  final bool isDark;
  const EmptyState({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.muted.withOpacity(0.08), borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.insights_rounded, size: 36, color: AppColors.muted.withOpacity(0.5))),
        const SizedBox(height: 16),
        Text('Нет данных', style: TextStyle(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text('Закройте смену, чтобы увидеть аналитику',
            style: TextStyle(fontSize: 13, color: AppColors.muted.withOpacity(0.6))),
      ]),
    );
  }
}

class YesterdayCard extends StatelessWidget {
  final ShiftRecord shift;
  final bool isDark;
  final String currency;
  const YesterdayCard({super.key, required this.shift, required this.isDark, required this.currency});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.ink;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.event_note_rounded, color: AppColors.orange, size: 20)),
              const SizedBox(width: 12),
              Text('Вчерашняя смена', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Итого', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              Text('${formatMoney(shift.revenue)} $currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.green)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            PaymentLine(label: 'QR-код', amount: shift.qr, currency: currency, isDark: isDark, color: PaymentColors.qr),
            const SizedBox(height: 8),
            PaymentLine(label: 'Банк. карта', amount: shift.card, currency: currency, isDark: isDark, color: PaymentColors.card),
            const SizedBox(height: 8),
            PaymentLine(label: 'Наличные', amount: shift.cash, currency: currency, isDark: isDark, color: PaymentColors.cash),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            PaymentLine(label: 'Касса: начало смены', amount: shift.morningCash, currency: currency, isDark: isDark, color: AppColors.muted),
            const SizedBox(height: 8),
            PaymentLine(label: 'Касса: конец смены', amount: shift.eveningCash, currency: currency, isDark: isDark, color: AppColors.muted),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(isDark ? 0.1 : 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    'Касса на начало сегодняшней смены: ${formatMoney(shift.eveningCash)} $currency',
                    style: TextStyle(fontSize: 12, color: AppColors.orange))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class PaymentLine extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isDark;
  final Color color;
  const PaymentLine({super.key, required this.label, required this.amount, required this.currency, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.8) : AppColors.ink))),
      Text('${formatMoney(amount)} $currency',
          style: TextStyle(
              fontFamily: AppFonts.mono,
              fontFamilyFallback: AppFonts.fallback,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.ink)),
    ]);
  }
}

class PeriodChip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const PeriodChip({super.key, required this.label, required this.selected, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? AppColors.orange.withOpacity(0.15) : Colors.white.withOpacity(isDark ? 0.06 : 0.5),
          border: Border.all(color: selected ? AppColors.orange.withOpacity(0.5) : Colors.white.withOpacity(0.15))),
        child: Text(label, style: TextStyle(fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppColors.orange : AppColors.muted)),
      ),
    );
  }
}

class WriteOffRow extends StatelessWidget {
  final String name;
  final int count, maxCount;
  final bool isDark;
  const WriteOffRow({super.key, required this.name, required this.count, required this.maxCount, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : count / maxCount;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.ink))),
          Text('$count шт', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.redAccent)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio, minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
          ),
        ),
      ]),
    );
  }
}
