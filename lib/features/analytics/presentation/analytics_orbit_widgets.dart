/// Элементы аналитики по макету «Орбита»: плитки итогов периода,
/// столбчатый график выручки и подсказка «Akyl думает».
library;

import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';

/// «1 210 000» → «1,21 млн», «172 400» → «172 тыс».
String compactMoney(double v) {
  final a = v.abs();
  String trim(String s) => s.replaceFirst(RegExp(r'[.,]?0+$'), '');
  if (a >= 1e6) return '${trim((v / 1e6).toStringAsFixed(2)).replaceAll('.', ',')} млн';
  if (a >= 1e3) return '${(v / 1e3).round()} тыс';
  return v.round().toString();
}

/// Итоги периода и изменение к такому же предыдущему периоду.
class PeriodStats {
  final double total;
  final double average;
  final double? totalChange;
  final double? averageChange;

  const PeriodStats(
      {required this.total,
      required this.average,
      this.totalChange,
      this.averageChange});

  static PeriodStats of(List<ShiftRecord> all, int days, {DateTime? now}) {
    final end = now ?? DateTime.now();
    final start = end.subtract(Duration(days: days));
    final prevStart = start.subtract(Duration(days: days));
    final cur = all.where((r) => r.date.isAfter(start) && !r.date.isAfter(end));
    final prev =
        all.where((r) => r.date.isAfter(prevStart) && !r.date.isAfter(start));
    double sum(Iterable<ShiftRecord> s) =>
        s.fold(0.0, (a, r) => a + r.revenue);
    double? pct(double a, double b) => b <= 0 ? null : (a - b) / b * 100;
    final total = sum(cur), prevTotal = sum(prev);
    final avg = cur.isEmpty ? 0.0 : total / cur.length;
    final prevAvg = prev.isEmpty ? 0.0 : prevTotal / prev.length;
    return PeriodStats(
      total: total,
      average: avg,
      totalChange: pct(total, prevTotal),
      averageChange: pct(avg, prevAvg),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final double? change;
  final bool isDark;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = change;
    return _Glass(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.ink)),
            ),
          ),
          if (c != null) ...[
            const SizedBox(width: 6),
            Text('${c >= 0 ? '+' : ''}${c.round()}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c >= 0 ? AppColors.green : Colors.redAccent)),
          ],
        ]),
      ]),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsets padding;
  const _Glass(
      {required this.child,
      required this.isDark,
      this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 14)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(isDark ? 0.07 : 0.62),
            border:
                Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.9)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Выручка по дням столбиками; последний день — цветом «действия».
class RevenueBars extends StatelessWidget {
  final List<ShiftRecord> records;
  final bool isDark;
  final String currency;

  const RevenueBars(
      {super.key,
      required this.records,
      required this.isDark,
      required this.currency});

  static const _days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

  @override
  Widget build(BuildContext context) {
    final maxY = records.isEmpty
        ? 100.0
        : records.map((r) => r.revenue).reduce((a, b) => a > b ? a : b) * 1.1;
    final many = records.length > 10;
    return _Glass(
      isDark: isDark,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('ВЫРУЧКА ПО ДНЯМ · ТЫС $currency',
              style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontFamilyFallback: AppFonts.fallback,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.muted)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: records.isEmpty
              ? Center(
                  child: Text('Нет данных за этот период',
                      style: TextStyle(color: AppColors.muted)))
              : BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 100 : maxY,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= records.length) {
                              return const SizedBox();
                            }
                            if (many && i % 5 != records.length % 5 - 1 &&
                                i != records.length - 1) {
                              return const SizedBox();
                            }
                            final d = records[i].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  many
                                      ? '${d.day}.${d.month.toString().padLeft(2, '0')}'
                                      : _days[d.weekday - 1],
                                  style: TextStyle(
                                      fontFamily: AppFonts.mono,
                                      fontSize: 10,
                                      color: AppColors.muted)),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                          '${rod.toY.toStringAsFixed(0)} $currency',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < records.length; i++)
                        BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: records[i].revenue,
                            width: many ? 6 : 22,
                            borderRadius: BorderRadius.circular(many ? 3 : 7),
                            color: i == records.length - 1
                                ? AppColors.greenLight
                                : AppColors.orange
                                    .withOpacity(isDark ? 0.75 : 0.55),
                          ),
                        ]),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }
}

/// «Akyl думает»: в какой день недели выручка заметно выше средней.
String? weekdayInsight(List<ShiftRecord> records) {
  if (records.length < 5) return null;
  const names = [
    'по понедельникам', 'по вторникам', 'по средам', 'по четвергам',
    'по пятницам', 'по субботам', 'по воскресеньям',
  ];
  const before = [
    'в воскресенье', 'в понедельник', 'во вторник', 'в среду',
    'в четверг', 'в пятницу', 'в субботу',
  ];
  final avg = records.fold(0.0, (a, r) => a + r.revenue) / records.length;
  if (avg <= 0) return null;
  final byDay = <int, List<double>>{};
  for (final r in records) {
    byDay.putIfAbsent(r.date.weekday, () => []).add(r.revenue);
  }
  int? best;
  var bestAvg = 0.0;
  byDay.forEach((d, v) {
    final a = v.reduce((x, y) => x + y) / v.length;
    if (a > bestAvg) {
      bestAvg = a;
      best = d;
    }
  });
  final pct = (bestAvg - avg) / avg * 100;
  if (best == null || pct < 10) return null;
  return '${names[best! - 1][0].toUpperCase()}${names[best! - 1].substring(1)} '
      'выручка выше средней на ${pct.round()}%. '
      'Заказывайте ходовые товары заранее — ${before[best! - 1]}.';
}

class AkylInsight extends StatelessWidget {
  final String text;
  final bool isDark;
  const AkylInsight({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Text('AKYL ДУМАЕТ',
              style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 10.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green)),
        ]),
        const SizedBox(height: 8),
        Text(text,
            style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: isDark ? Colors.white : AppColors.ink)),
      ]),
    );
  }
}
