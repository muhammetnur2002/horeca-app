import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  int _periodDays = 7;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final repo = ref.read(analyticsRepositoryProvider);
    final currency = ref.watch(settingsRepositoryProvider).currency;
    final records = repo.getLastNDays(_periodDays);
    final changePercent = repo.getRevenueChangePercent();
    final topWriteOffs = repo.getTopWriteOffs(limit: 5);
    final yesterdayShift = repo.getYesterdayShift();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Аналитика и инсайты',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: records.isEmpty
              ? _EmptyState(isDark: isDark)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      final t = Curves.easeOutCubic.transform(_animCtrl.value);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 24),
                          child: child,
                        ),
                      );
                    },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Сравнение смен
                      if (changePercent != null)
                        _ChangeCard(percent: changePercent, isDark: isDark, currency: currency),
                      const SizedBox(height: 16),

                      // Вчерашняя смена по способам оплаты
                      if (yesterdayShift != null) ...[
                        _YesterdayCard(shift: yesterdayShift, isDark: isDark, currency: currency),
                      const SizedBox(height: 16),
                      ],

                      // Период выбора
                      Row(children: [
                        _PeriodChip(label: '7 дней', selected: _periodDays == 7, isDark: isDark,
                            onTap: () => setState(() => _periodDays = 7)),
                        const SizedBox(width: 8),
                        _PeriodChip(label: '30 дней', selected: _periodDays == 30, isDark: isDark,
                            onTap: () => setState(() => _periodDays = 30)),
                      ]),
                      const SizedBox(height: 16),

                      // График выручки
                      Text('Выручка по дням', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 12),
                      _RevenueChart(records: records, isDark: isDark, currency: currency),
                      const SizedBox(height: 24),

                      // Топ списаний
                      Text('Топ списываемых товаров', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 12),
                      if (topWriteOffs.isEmpty)
                        Text('Нет данных о списаниях', style: const TextStyle(fontSize: 13, color: AppColors.muted))
                      else
                        ...topWriteOffs.entries.map((e) => _WriteOffRow(
                          name: e.key, count: e.value, isDark: isDark,
                          maxCount: topWriteOffs.values.first,
                        )),
                    ]),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
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

class _YesterdayCard extends StatelessWidget {
  final ShiftRecord shift;
  final bool isDark;
  final String currency;
  const _YesterdayCard({required this.shift, required this.isDark, required this.currency});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
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
                  child: const Icon(Icons.event_note_rounded, color: AppColors.orange, size: 20)),
              const SizedBox(width: 12),
              Text('Вчерашняя смена', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Итого', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              Text('${shift.revenue.toStringAsFixed(0)} $currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.green)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            _PaymentLine(label: 'QR-код', amount: shift.qr, currency: currency, isDark: isDark, color: AppColors.green),
            const SizedBox(height: 8),
            _PaymentLine(label: 'Банк. карта', amount: shift.card, currency: currency, isDark: isDark, color: const Color(0xFF378ADD)),
            const SizedBox(height: 8),
            _PaymentLine(label: 'Наличные', amount: shift.cash, currency: currency, isDark: isDark, color: AppColors.orange),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            _PaymentLine(label: 'Касса: начало смены', amount: shift.morningCash, currency: currency, isDark: isDark, color: AppColors.muted),
            const SizedBox(height: 8),
            _PaymentLine(label: 'Касса: конец смены', amount: shift.eveningCash, currency: currency, isDark: isDark, color: AppColors.muted),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(isDark ? 0.1 : 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    'Касса на начало сегодняшней смены: ${shift.eveningCash.toStringAsFixed(0)} $currency',
                    style: const TextStyle(fontSize: 12, color: AppColors.orange))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PaymentLine extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isDark;
  final Color color;
  const _PaymentLine({required this.label, required this.amount, required this.currency, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1A1A2E)))),
      Text('${amount.toStringAsFixed(0)} $currency',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
    ]);
  }
}
class _ChangeCard extends StatelessWidget {
  final double percent;
  final bool isDark;
  final String currency;
  const _ChangeCard({required this.percent, required this.isDark, required this.currency});
  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final color = isUp ? AppColors.green : Colors.redAccent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(isDark ? 0.1 : 0.06),
            border: Border.all(color: color.withOpacity(0.3))),
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Сегодня выручка ${isUp ? "выше" : "ниже"} на ${percent.abs().toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              const SizedBox(height: 2),
              Text('по сравнению с предыдущей сменой', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.selected, required this.isDark, required this.onTap});
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

class _RevenueChart extends StatelessWidget {
  final List<ShiftRecord> records;
  final bool isDark;
  final String currency;
  const _RevenueChart({required this.records, required this.isDark, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return SizedBox(height: 200, child: Center(
          child: Text('Нет данных за этот период', style: const TextStyle(color: AppColors.muted))));
    }
    final maxY = records.map((r) => r.revenue).reduce((a, b) => a > b ? a : b) * 1.2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY <= 0 ? 100 : maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= records.length) return const SizedBox();
                    final d = records[i].date;
                    return Padding(padding: const EdgeInsets.only(top: 6),
                        child: Text('${d.day}.${d.month.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 10, color: AppColors.muted)));
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(records.length, (i) => FlSpot(i.toDouble(), records[i].revenue)),
                  isCurved: true,
                  color: AppColors.orange,
                  barWidth: 3,
                  dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(radius: 4, color: AppColors.orange, strokeWidth: 2,
                          strokeColor: isDark ? const Color(0xFF1A1E2E) : Colors.white)),
                  belowBarData: BarAreaData(show: true,
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [AppColors.orange.withOpacity(0.25), AppColors.orange.withOpacity(0.0)])),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) =>
                      LineTooltipItem('${s.y.toStringAsFixed(0)} $currency',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WriteOffRow extends StatelessWidget {
  final String name;
  final int count, maxCount;
  final bool isDark;
  const _WriteOffRow({required this.name, required this.count, required this.maxCount, required this.isDark});
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
              color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
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


