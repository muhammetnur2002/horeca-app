import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/pdf_generator/pdf_saver.dart';
import 'package:horeca_app/features/iiko/data/iiko_consumption.dart';
import 'package:horeca_app/features/iiko/data/iiko_repository.dart';
import 'package:horeca_app/features/iiko/data/iiko_service.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/supply/data/excel_stock_report.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/consumption.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';
import 'package:horeca_app/features/supply/presentation/stock_levels_bridge.dart';

class StockReportSection extends ConsumerStatefulWidget {
  final int periodDays;
  final bool isDark;
  const StockReportSection({super.key, required this.periodDays, required this.isDark});

  @override
  ConsumerState<StockReportSection> createState() => _StockReportSectionState();
}

class _StockReportSectionState extends ConsumerState<StockReportSection> {
  bool _busy = false;
  String? _notice;

  Future<void> _excel(List<StockReportRow> rows, DateTime from, DateTime to) async {
    if (rows.isEmpty) {
      setState(() => _notice = 'За этот срок таблица пустая. Excel не собран.');
      return;
    }
    try {
      final bytes = await buildStockExcel(rows: rows, from: from, to: to);
      await saveFile(
        bytes,
        stockExcelFileName(from, to),
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (_) {
      if (mounted) setState(() => _notice = 'Excel не собрался.');
    }
  }

  Future<void> _pullIiko(DateTime from, DateTime to) async {
    final config = ref.read(iikoRepositoryProvider);
    final login = await ref.read(iikoRepositoryProvider.notifier).getApiLogin();
    if (!mounted) return;
    if (login == null || login.isEmpty || config.organizationId == null) {
      setState(() => _notice = 'iiko не подключён. Расход по чекам не записан. Списания со смены на месте.');
      return;
    }
    setState(() {
      _busy = true;
      _notice = 'Спрашиваю продажи и техкарты iiko…';
    });
    try {
      final service = IikoService();
      final token = await service.getAccessToken(login);
      final nomenclature = await service.getNomenclature(token, config.organizationId!);
      final names = {for (final product in nomenclature.products) product.id: product.name};
      final result = await IikoConsumptionClient().pull(
        token: token,
        organizationId: config.organizationId!,
        from: from,
        to: to,
        productNames: names,
      );
      if (!mounted) return;
      if (!result.hasSales) {
        setState(() => _notice = result.salesError);
        return;
      }
      if (result.cards.isEmpty) {
        setState(() => _notice =
            result.cardsError ?? 'Техкарты не пришли. Расход по ингредиентам не записан.');
        return;
      }
      final products = ref.read(settingsRepositoryProvider).products;
      final daily = dailyConsumptionMoves(
        sales: result.sales,
        cardsByDish: result.cards,
        keyFor: (name) => stockKeyFor(products, name),
      );
      if (result.sales.isNotEmpty && daily.undatedSales == result.sales.length) {
        setState(() => _notice =
            'iiko не отдал продажи по дням. Расход не записан, нули не подставлены.');
        return;
      }
      if (daily.moves.isEmpty) {
        final sample = daily.dishesWithoutCard.take(6).join(', ');
        setState(() => _notice = sample.isEmpty
            ? 'Продаж с техкартами за срок нет. Расход не записан.'
            : 'Техкарты не совпали с блюдами ($sample). Расход не записан.');
        return;
      }
      ref.read(supplyRepositoryProvider.notifier).replaceConsumption(
            from: from,
            to: to,
            consumption: daily.moves,
          );
      applyComputedStock(ref);
      final skipped = daily.dishesWithoutCard;
      setState(() => _notice = skipped.isEmpty
          ? 'Расход по техкартам записан по дням.'
          : 'Расход записан. Без техкарты не списаны: ${skipped.take(6).join(', ')}.');
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'iiko не ответил. Расход не записан, нули не подставлены.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(Duration(days: widget.periodDays));
    final moves = ref.watch(supplyRepositoryProvider).moves;
    final products = ref.watch(settingsRepositoryProvider).products;
    final rows = buildStockReport(
      moves: moves,
      from: from,
      to: now,
      minimums: minimumsByKey(products),
    );
    final counted = rows.any((row) => row.countedInPeriod);
    final mixed = [for (final row in rows) if (row.mixedUnits) row.name];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Остатки за период',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
      const SizedBox(height: 6),
      const Text(
        'Зелёный — много, жёлтый — мало, красный — плохо, без метки — норма. '
        'Порог «много» — в 3 раза выше минимума товара.',
        style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
      ),
      if (counted) ...[
        const SizedBox(height: 6),
        const Text(
          'В периоде была инвентаризация: остаток заменён на посчитанный факт.',
          style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
        ),
      ],
      if (mixed.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          'Разные единицы у товаров: ${mixed.take(4).join(', ')}. Строки в '
          'несовместимой единице (шт против кг или л) в остаток не вошли — '
          'проверьте единицу товара в каталоге.',
          style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
        ),
      ],
      const SizedBox(height: AppMetrics.gap),
      if (rows.isEmpty)
        const Text('За этот срок нет прихода, расхода и списаний.',
            style: TextStyle(fontSize: 13, color: AppColors.muted))
      else
        for (final row in rows) _ReportRow(row: row, textColor: textColor, isDark: widget.isDark),
      if (_notice != null) ...[
        const SizedBox(height: 8),
        Text(_notice!, style: TextStyle(fontSize: 13, height: 1.35, color: textColor)),
      ],
      if (_busy) const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(color: AppColors.orange),
      ),
      const SizedBox(height: AppMetrics.gap),
      ElevatedButton(
        onPressed: _busy ? null : () => _excel(rows, from, now),
        child: const Text('Скачать Excel'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _busy ? null : () => _pullIiko(from, now),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: BorderSide(color: AppColors.orange.withOpacity(0.45)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Подтянуть расход из iiko'),
      ),
    ]);
  }
}

class _ReportRow extends StatelessWidget {
  final StockReportRow row;
  final Color textColor;
  final bool isDark;
  const _ReportRow({required this.row, required this.textColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = switch (row.mark) {
      StockMark.high => AppColors.markHigh,
      StockMark.low => AppColors.markLow,
      StockMark.bad => AppColors.markBad,
      StockMark.stable => Colors.transparent,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.radius),
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.65),
        border: Border(left: BorderSide(color: color, width: row.mark == StockMark.stable ? 0 : 4)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.name, style: TextStyle(fontSize: 14, color: textColor)),
            const SizedBox(height: 2),
            Text(
              'приход ${_fmt(row.incoming)} · расход ${_fmt(row.consumption)} · списания ${_fmt(row.writeOff)}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmt(row.closing),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
          Text(row.mark == StockMark.stable ? row.unit : stockMarkLabel(row.mark),
              style: TextStyle(fontSize: 13, color: row.mark == StockMark.stable ? AppColors.muted : color)),
        ]),
      ]),
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
