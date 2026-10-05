import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/history/presentation/history_dialogs.dart';
import 'package:horeca_app/shared/widgets/orbit_kit.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

/// Экран "История" (заявки/инвентаризации): записи одной стеклянной группой,
/// нижний лист с деталями — в history_dialogs.dart.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(historyEntriesProvider);
    final repo = ref.read(historyRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.history,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.muted,
            ),
            onPressed: () => _confirmClear(context, repo, l10n),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.5),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.6),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.orange,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.muted,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: l10n.requestsTab),
                      Tab(text: l10n.inventoryTab),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: BackdropGradient(isDark),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(
              entries.where((e) => e.type == HistoryType.request).toList(),
              context,
              isDark,
              l10n.requestsTab,
              Icons.assignment_outlined,
            ),
            _buildList(
              entries.where((e) => e.type == HistoryType.inventory).toList(),
              context,
              isDark,
              l10n.inventoryTab,
              Icons.inventory_2_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<HistoryEntry> entries,
    BuildContext ctx,
    bool isDark,
    String tabName,
    IconData emptyIcon,
  ) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.muted.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                emptyIcon,
                size: 36,
                color: AppColors.muted.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет записей',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$tabName появятся здесь',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Записи одной стеклянной группой, как в макете: иконка типа,
    // название, дата моноширинным; нажатие — подробности.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 140, 16, 24),
      children: [
        OrbitGroup(children: [
          for (final e in entries)
            OrbitRow(
              icon: e.type == HistoryType.request
                  ? Icons.description_outlined
                  : Icons.inventory_2_outlined,
              iconColor: e.type == HistoryType.request
                  ? AppColors.orange
                  : Colors.amber,
              title: e.title,
              subtitle: _historyDate(e.createdAt),
              monoSubtitle: true,
              onTap: () => showHistoryDetail(ctx, e),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: 'Поделиться',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.share_outlined,
                      size: 18, color: AppColors.muted),
                  onPressed: () => Share.share(e.text),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white54 : AppColors.inkSoft),
              ]),
            ),
        ]),
      ],
    );
  }

  static String _historyDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(d.hour)}:${two(d.minute)}';
    if (day == today) return 'сегодня, $time';
    if (day == today.subtract(const Duration(days: 1))) return 'вчера, $time';
    const m = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return '${d.day} ${m[d.month - 1]}, $time';
  }

  void _confirmClear(
      BuildContext context, dynamic repo, AppLocalizations l10n) {
    final type =
        _tabController.index == 0 ? HistoryType.request : HistoryType.inventory;
    repo.clearByType(type, staffId: ref.read(authRepositoryProvider).staffId);
    ref.invalidate(historyEntriesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('История очищена',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.darkCard2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
