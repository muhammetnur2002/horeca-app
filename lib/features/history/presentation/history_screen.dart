import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/history/presentation/history_dialogs.dart';
import 'package:horeca_app/features/history/presentation/history_widgets.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

/// Экран "История" (заявки/инвентаризации). Карточка записи вынесена в
/// history_widgets.dart, нижний лист с деталями — в history_dialogs.dart.
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
    final repo = ref.read(historyRepositoryProvider);
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
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0F1629),
                    Color(0xFF1A1040),
                    Color(0xFF0D1F35)
                  ]
                : const [
                    Color(0xFFEEF2FF),
                    Color(0xFFF5F7FF),
                    Color(0xFFEEF2FF)
                  ],
          ),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 140, 16, 16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[entries.length - 1 - i]; // новые сверху
        return HistoryCard(
          entry: e,
          isDark: isDark,
          onShare: () => Share.share(e.text),
          onTap: () => showHistoryDetail(ctx, e),
        );
      },
    );
  }

  void _confirmClear(
      BuildContext context, dynamic repo, AppLocalizations l10n) {
    final type =
        _tabController.index == 0 ? HistoryType.request : HistoryType.inventory;
    repo.clearByType(type);
    ref.invalidate(historyEntriesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('История очищена',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E3352),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
