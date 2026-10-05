/// «Учёт товара»: остатки и расход за период по журналу движений,
/// список приёмок поставок, переходы к приёмке, стартовым остаткам
/// и журналу действий.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/domain/stock_ledger.dart';
import 'package:horeca_app/features/stock/presentation/audit_screen.dart';
import 'package:horeca_app/features/stock/presentation/baseline_screen.dart';
import 'package:horeca_app/features/stock/presentation/receipt_screen.dart';
import 'package:horeca_app/features/stock/presentation/stock_widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Период отчёта.
enum StockPeriod {
  week('7 дней', 7),
  month('30 дней', 30),
  quarter('90 дней', 90);

  final String label;
  final int days;
  const StockPeriod(this.label, this.days);
}

final _periodProvider =
    StateProvider.autoDispose<StockPeriod>((_) => StockPeriod.month);

final _ledgerProvider =
    FutureProvider.autoDispose<(Map<String, LedgerLine>, bool)>((ref) async {
  ref.watch(stockRevisionProvider);
  final period = ref.watch(_periodProvider);
  final repo = ref.watch(stockRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final ledger = await repo.ledger(
    from: today.subtract(Duration(days: period.days - 1)),
    to: now.add(const Duration(seconds: 1)),
  );
  return (ledger, await repo.hasAnyCount());
});

final _receiptsProvider =
    FutureProvider.autoDispose<List<HistoryEntryRow>>((ref) {
  ref.watch(stockRevisionProvider);
  return ref.watch(stockRepositoryProvider).documents('receipt');
});

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authRepositoryProvider).role != UserRole.staff;
    return DefaultTabController(
      length: 2,
      child: StockScaffold(
        title: 'Учёт товара',
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Журнал действий',
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: () => _open(context, const AuditScreen()),
            ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(children: [
                Expanded(
                  child: StockPrimaryButton(
                    label: 'Принять поставку',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () => _open(context, const ReceiptScreen()),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _open(context, const BaselineScreen()),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Стартовые\nостатки',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ]),
            ),
            TabBar(
              labelColor: AppColors.orange,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.orange,
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: 'Остатки и расход'), Tab(text: 'Приёмки')],
            ),
            const Expanded(
              child: TabBarView(children: [_LedgerTab(), _ReceiptsTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTab extends ConsumerStatefulWidget {
  const _LedgerTab();

  @override
  ConsumerState<_LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends ConsumerState<_LedgerTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final period = ref.watch(_periodProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final data = ref.watch(_ledgerProvider);

    final header = <Widget>[
      Wrap(spacing: 8, children: [
        for (final p in StockPeriod.values)
          ChoiceChip(
            label: Text(p.label),
            selected: p == period,
            selectedColor: AppColors.orange.withOpacity(0.2),
            onSelected: (_) => ref.read(_periodProvider.notifier).state = p,
          ),
      ]),
      const SizedBox(height: 8),
      TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: const InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Поиск товара',
        ),
      ),
      const SizedBox(height: 10),
    ];

    return switch (data) {
      AsyncData(value: (final ledger, final hasCount)) => () {
          final q = _query.trim().toLowerCase();
          final products = settings.products
              .where((p) =>
                  ledger.containsKey(p.id) &&
                  (q.isEmpty || p.name.toLowerCase().contains(q)))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              ...header,
              if (!hasCount)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    borderColor: AppColors.orange.withOpacity(0.5),
                    child: Text(
                      'Чтобы приложение считало остатки, нужна точка отсчёта: '
                      'введите «Стартовые остатки» (последнюю полную '
                      'инвентаризацию) или проведите инвентаризацию. '
                      'Дальше: остаток = начало + приход − списания − расход.',
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                  ),
                ),
              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'За выбранный период движений нет.\nПриёмки, инвентаризации '
                    'и списания десертов на закрытии смены появятся здесь.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final p in products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LedgerCard(
                    name: p.name,
                    unit: p.inventoryUnit,
                    line: ledger[p.id]!,
                    minStock: p.minStock,
                    textColor: textColor,
                  ),
                ),
            ],
          );
        }(),
      AsyncError(:final error) => Center(child: Text('Ошибка: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _LedgerCard extends StatelessWidget {
  final String name;
  final String unit;
  final LedgerLine line;
  final double? minStock;
  final Color textColor;

  const _LedgerCard({
    required this.name,
    required this.unit,
    required this.line,
    required this.minStock,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final end = line.end;
    final low = end != null && minStock != null && end < minStock!;
    Widget stat(String label, double v, Color color) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text('$label ${fmtQty(v)}',
              style: TextStyle(fontSize: 12.5, color: color)),
        );
    return GlassCard(
      borderColor: low ? Colors.amber.withOpacity(0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(name,
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            ),
            Text(end == null ? '—' : '${fmtQty(end)} $unit',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: low ? Colors.amber : textColor)),
          ]),
          const SizedBox(height: 6),
          Wrap(children: [
            if (line.start != null)
              stat('Начало', line.start!, AppColors.muted),
            if (line.received != 0)
              stat('Приход +', line.received, AppColors.green),
            if (line.writtenOff != 0)
              stat('Списано −', line.writtenOff, Colors.redAccent),
            if (line.sold != 0) stat('Продано −', line.sold, AppColors.muted),
            if (line.consumption != 0)
              stat(line.consumption > 0 ? 'Расход −' : 'Излишек +',
                  line.consumption.abs(), AppColors.orange),
          ]),
          if (line.lastCountAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Последний подсчёт: ${fmtDate(line.lastCountAt!)}',
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _ReceiptsTab extends ConsumerWidget {
  const _ReceiptsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final data = ref.watch(_receiptsProvider);
    return switch (data) {
      AsyncData(:final value) when value.isNotEmpty => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          itemCount: value.length,
          itemBuilder: (_, i) {
            final r = value[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                onTap: () => _showReceipt(context, r),
                child: Row(children: [
                  Icon(Icons.local_shipping_outlined, color: AppColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: textColor)),
                        Text(fmtDate(r.createdAt.toLocal()),
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  if (r.attachmentPath != null)
                    Icon(Icons.photo_outlined,
                        size: 18, color: AppColors.muted),
                  if (r.body.contains('Не пришло') ||
                      r.body.contains('Пришло не всё'))
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.amber),
                    ),
                ]),
              ),
            );
          },
        ),
      AsyncData() => const StockEmpty(
          icon: Icons.local_shipping_outlined,
          title: 'Приёмок пока нет',
          subtitle: 'Когда придёт поставка, нажмите «Принять поставку» '
              'и отметьте, что пришло по заявке.',
        ),
      AsyncError(:final error) => Center(child: Text('Ошибка: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  void _showReceipt(BuildContext context, HistoryEntryRow r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text(r.body, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
            if (r.attachmentPath != null && !kIsWeb)
              GestureDetector(
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => _PhotoView(path: r.attachmentPath!))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(r.attachmentPath!),
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Фото накладной не найдено на устройстве'),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Share.share(r.body),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Поделиться'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoView extends StatelessWidget {
  final String path;
  const _PhotoView({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Накладная'),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.file(File(path))),
      ),
    );
  }
}
