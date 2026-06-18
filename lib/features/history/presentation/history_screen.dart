import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  
  get _selectedTab => null;

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
    final l10n = AppLocalizations.of(context)!;
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
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                
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
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)],
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
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[entries.length - 1 - i]; // новые сверху
        return _HistoryCard(
          entry: e,
          isDark: isDark,
          onShare: () => Share.share(e.text),
          onTap: () => _showDetail(ctx, e),
        );
      },
    );
  }

  void _showDetail(BuildContext ctx, HistoryEntry e) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                ),
              ),
              child: Column(
                children: [
                  // Хэндл
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Заголовок
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Share.share(e.text),
                          icon: const Icon(Icons.share_outlined),
                          color: AppColors.orange,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Контент
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(20),
                      child: SelectableText(
                        e.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? Colors.white.withOpacity(0.85)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmClear(
    BuildContext context, dynamic repo, AppLocalizations l10n) {
  final type = _selectedTab == 0
      ? HistoryType.request
      : HistoryType.inventory;
  repo.clearByType(type);
  ref.invalidate(historyEntriesProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('История очищена'),
      backgroundColor: AppColors.darkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
  );
}
  }


// ── Карточка истории ──────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.entry,
    required this.isDark,
    required this.onShare,
    required this.onTap,
  });

  String _formatDate(DateTime dt) {
    const months = [
      '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month]}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
              ),
            ),
            child: Row(
              children: [
                // Иконка типа
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    entry.type == HistoryType.request
                        ? Icons.assignment_outlined
                        : Icons.inventory_2_outlined,
                    color: AppColors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Текст
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.text.length > 60
                            ? '${entry.text.substring(0, 60)}...'
                            : entry.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(entry.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Кнопка поделиться
                IconButton(
                  onPressed: onShare,
                  icon: Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
