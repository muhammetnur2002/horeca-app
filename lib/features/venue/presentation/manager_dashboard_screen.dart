import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_data.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_insights.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_models.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_widgets.dart';

/// Дашборд управляющего. Сознательно НЕ хранит и не кэширует данные
/// локально — читает Firestore напрямую при каждом открытии/обновлении.
/// Управляющий видит все заведения аккаунта сразу, но для этого экрану
/// всегда нужен интернет (в отличие от остального приложения, которое
/// работает полностью офлайн).
///
/// Модели (VenueSnapshot/Insight), генерация текстовых инсайтов и мелкие
/// виджеты вынесены в manager_dashboard_models.dart /
/// manager_dashboard_insights.dart / manager_dashboard_widgets.dart —
/// здесь остаются только загрузка данных и сборка экрана.
class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  Future<List<VenueSnapshot>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = ref.read(accountRepositoryProvider).uid;
    setState(() {
      _future = uid == null ? Future.value(<VenueSnapshot>[]) : fetchVenueSnapshots(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final accountState = ref.watch(accountRepositoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Дашборд управляющего',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _load,
          ),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                            : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: !accountState.isLoggedIn
              ? _buildNotLoggedIn(textColor)
              : FutureBuilder<List<VenueSnapshot>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.orange));
                    }
                    final data = snap.data ?? const <VenueSnapshot>[];
                    if (data.isEmpty) return _buildEmpty(textColor);
                    return _buildContent(data, isDark, textColor);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildNotLoggedIn(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('Нужен вход в облачный аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Text(
            'Дашборд управляющего работает только при входе в аккаунт и наличии '
            'интернета — он специально не хранит данные локально на устройстве.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 48),
          const SizedBox(height: 16),
          Text('Не удалось загрузить данные',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Text('Проверьте интернет-соединение и попробуйте снова.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            child: const Text('Обновить'),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent(List<VenueSnapshot> data, bool isDark, Color textColor) {
    final totalToday = data.fold<double>(0, (s, v) => s + v.todayRevenue);
    final totalYesterday = data.fold<double>(0, (s, v) => s + v.yesterdayRevenue);
    final Map<String, int> combinedWriteOffs = {};
    for (final v in data) {
      v.writeOffsTotal.forEach((name, qty) {
        combinedWriteOffs[name] = (combinedWriteOffs[name] ?? 0) + qty;
      });
    }
    final sortedWriteOffs = combinedWriteOffs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalWeekRevenue = data.fold<double>(0, (s, v) => s + v.weekRevenue);
    final totalPrevWeekRevenue = data.fold<double>(0, (s, v) => s + v.prevWeekRevenue);
    final Map<String, int> combinedWeekWriteOffs = {};
    final Map<String, int> combinedPrevWeekWriteOffs = {};
    for (final v in data) {
      v.weekWriteOffs.forEach((name, qty) {
        combinedWeekWriteOffs[name] = (combinedWeekWriteOffs[name] ?? 0) + qty;
      });
      v.prevWeekWriteOffs.forEach((name, qty) {
        combinedPrevWeekWriteOffs[name] = (combinedPrevWeekWriteOffs[name] ?? 0) + qty;
      });
    }
    final insights = generateDashboardInsights(
      weekRevenue: totalWeekRevenue,
      prevWeekRevenue: totalPrevWeekRevenue,
      weekWriteOffs: combinedWeekWriteOffs,
      prevWeekWriteOffs: combinedPrevWeekWriteOffs,
    );

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () async => _load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 90, 16, 40),
        children: [
          GlassCard(
            isDark: isDark,
            accentColor: AppColors.green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ВЫРУЧКА СЕГОДНЯ — ВСЕ ЗАВЕДЕНИЯ',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6)),
                const SizedBox(height: 6),
                Text(formatDashboardMoney(totalToday),
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.green)),
                if (totalYesterday > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${totalToday >= totalYesterday ? '+' : ''}'
                    '${(((totalToday - totalYesterday) / totalYesterday) * 100).toStringAsFixed(0)}% к вчера',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('СВОДКА ЗА НЕДЕЛЮ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 0.6)),
            const SizedBox(height: 10),
            GlassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < insights.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    InsightRow(insight: insights[i], isDark: isDark),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('ПО ЗАВЕДЕНИЯМ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          ...data.map((v) => VenueCard(snapshot: v, isDark: isDark)),
          if (sortedWriteOffs.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('ТОП СПИСАНИЙ ПО ВСЕМ ЗАВЕДЕНИЯМ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 0.6)),
            const SizedBox(height: 10),
            GlassCard(
              isDark: isDark,
              child: Column(
                children: sortedWriteOffs.take(5).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                        Text('${e.value} шт',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
