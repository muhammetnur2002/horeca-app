import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      backgroundColor: isDark ? const Color(0xFF1A1C2B) : const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: Text(l10n.history),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Заявки'),
            Tab(text: 'Инвентаризации'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              final isRequestsTab = _tabController.index == 0;
              final type = isRequestsTab ? HistoryType.request : HistoryType.inventory;
              final title = isRequestsTab ? 'Заявки' : 'Инвентаризации';

              // Мгновенная очистка
              repo.clearByType(type);
              ref.invalidate(historyEntriesProvider);

              // Показываем SnackBar, который исчезает через 2 секунды
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title очищены'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(entries.where((e) => e.type == HistoryType.request).toList(), context, isDark),
          _buildList(entries.where((e) => e.type == HistoryType.inventory).toList(), context, isDark),
        ],
      ),
    );
  }

  Widget _buildList(List<HistoryEntry> entries, BuildContext ctx, bool isDark) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Нет записей',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return Card(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          child: ListTile(
            title: Text(e.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            subtitle: Text(
              e.text.length > 80 ? '${e.text.substring(0, 80)}...' : e.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            trailing: IconButton(
              icon: Icon(Icons.share, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Share.share(e.text),
            ),
            onTap: () => showDialog(
              context: ctx,
              builder: (_) => AlertDialog(
                content: SingleChildScrollView(child: SelectableText(e.text)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}