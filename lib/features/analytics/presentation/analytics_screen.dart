import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/analytics/presentation/analytics_orbit_widgets.dart';
import 'package:horeca_app/features/analytics/presentation/analytics_widgets.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

/// Экран "Аналитика и инсайты". Мелкие карточки/график вынесены в
/// analytics_widgets.dart, чтобы не раздувать build().
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
    final textColor = isDark ? Colors.white : AppColors.ink;
    // watch — экран перестраивается, когда смены догрузятся из базы.
    ref.watch(analyticsRepositoryProvider);
    final repo = ref.read(analyticsRepositoryProvider.notifier);
    final currency = ref.watch(settingsRepositoryProvider).currency;
    final records = repo.getLastNDays(_periodDays);
    final stats = PeriodStats.of(repo.getAll(), _periodDays);
    final insight = weekdayInsight(repo.getLastNDays(56));
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
        title: Text('Аналитика',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: BackdropGradient(isDark)))),
        SafeArea(
          child: records.isEmpty
              ? EmptyState(isDark: isDark)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
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
                      // Итоги периода и изменение к предыдущему такому же
                      Row(children: [
                        Expanded(child: StatTile(
                          label: 'Выручка за $_periodDays дней',
                          value: compactMoney(stats.total),
                          change: stats.totalChange,
                          isDark: isDark,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: StatTile(
                          label: 'Средняя смена',
                          value: compactMoney(stats.average),
                          change: stats.averageChange,
                          isDark: isDark,
                        )),
                      ]),
                      const SizedBox(height: 16),

                      // Период выбора
                      Row(children: [
                        PeriodChip(label: '7 дней', selected: _periodDays == 7, isDark: isDark,
                            onTap: () => setState(() => _periodDays = 7)),
                        const SizedBox(width: 8),
                        PeriodChip(label: '30 дней', selected: _periodDays == 30, isDark: isDark,
                            onTap: () => setState(() => _periodDays = 30)),
                      ]),
                      const SizedBox(height: 16),

                      // График выручки
                      RevenueBars(records: records, isDark: isDark, currency: currency),
                      if (insight != null) ...[
                        const SizedBox(height: 12),
                        AkylInsight(text: insight, isDark: isDark),
                      ],
                      const SizedBox(height: 16),
                      // Вчерашняя смена по способам оплаты
                      if (yesterdayShift != null) ...[
                        YesterdayCard(shift: yesterdayShift, isDark: isDark, currency: currency),
                      const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 8),

                      // Топ списаний
                      Text('Топ списываемых товаров', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(height: 12),
                      if (topWriteOffs.isEmpty)
                        Text('Нет данных о списаниях', style: TextStyle(fontSize: 13, color: AppColors.muted))
                      else
                        ...topWriteOffs.entries.map((e) => WriteOffRow(
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
