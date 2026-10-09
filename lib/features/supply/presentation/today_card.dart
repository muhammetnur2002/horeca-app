import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/supply_models.dart';

class TodaySupplyCard extends ConsumerWidget {
  final bool isDark;
  const TodaySupplyCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(supplyRepositoryProvider);
    final request = pickRequestToReceive(snapshot.requests, DateTime.now());
    final receipt = receiptForRequest(snapshot.receipts, request?.id);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return AnimatedSize(
      duration: AppMetrics.motion,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppMetrics.radius),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.72),
          border: Border.all(color: AppColors.orange.withOpacity(0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_title(request),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          Text(_body(request, receipt),
              style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted)),
          if (receipt != null) ...[
            const SizedBox(height: 10),
            _Counts(receipt: receipt, textColor: textColor),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/receipt'),
              child: const Text('Открыть приёмку'),
            ),
          ),
        ]),
      ),
    );
  }

  String _title(SupplyRequest? request) {
    if (request == null) return 'Сегодня';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (!request.createdAt.isBefore(yesterday) && request.createdAt.isBefore(today)) {
      return 'Вчерашняя заявка';
    }
    if (!request.createdAt.isBefore(today)) return 'Заявка сегодня';
    return 'Заявка от ${request.createdAt.day}.${request.createdAt.month}';
  }

  String _body(SupplyRequest? request, GoodsReceipt? receipt) {
    if (request == null) {
      return 'Заявки ещё нет. Новая заявка запомнится, и на следующий день её можно сверить с накладной.';
    }
    final positions = '${request.lines.length}';
    if (receipt == null) {
      return '$positions поз. ещё без накладной. Приёмка покажет, что приехало, чего нет и что лишнее.';
    }
    return '$positions поз. в заявке. Последняя приёмка уже в остатке.';
  }
}

class _Counts extends StatelessWidget {
  final GoodsReceipt receipt;
  final Color textColor;
  const _Counts({required this.receipt, required this.textColor});

  @override
  Widget build(BuildContext context) {
    int count(ReceiptStatus status) =>
        receipt.lines.where((line) => line.status == status).length;
    final items = [
      ('${count(ReceiptStatus.matched)}', 'как заказали', AppColors.markHigh),
      ('${count(ReceiptStatus.short)}', 'меньше', AppColors.markLow),
      ('${count(ReceiptStatus.missing)}', 'не привезли', AppColors.markBad),
      ('${count(ReceiptStatus.extra)}', 'лишнее', AppColors.orange),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Column(children: [
              Text(item.$1,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
              Text(item.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: item.$3)),
            ]),
          ),
      ],
    );
  }
}
