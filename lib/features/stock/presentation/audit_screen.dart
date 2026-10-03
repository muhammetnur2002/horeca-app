/// Журнал действий: кто и когда принял поставку, ввёл стартовые остатки,
/// провёл инвентаризацию. Записи нельзя изменить или удалить.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/features/auth/data/staff_pin_service.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/presentation/stock_widgets.dart';

final _auditProvider =
    FutureProvider.autoDispose<(List<AuditLogRow>, Map<String, String>)>(
        (ref) async {
  ref.watch(stockRevisionProvider);
  final rows = await ref.watch(stockRepositoryProvider).audit();
  final staff = await ref.watch(staffPinServiceProvider).loadStaff();
  return (rows, {for (final s in staff) s.id: s.fullName});
});

Map<String, dynamic> _after(AuditLogRow r) {
  try {
    if (r.afterJson != null) {
      return jsonDecode(r.afterJson!) as Map<String, dynamic>;
    }
  } catch (_) {}
  return const {};
}

String describeAudit(AuditLogRow r) {
  final after = _after(r);
  switch (r.entity) {
    case 'receipt':
      final short = (after['short'] as int?) ?? 0;
      return 'Принята поставка: позиций ${after['lines'] ?? '?'}'
          '${short > 0 ? ', недовоз по $short' : ''}'
          '${after['photo'] == true ? ', есть фото накладной' : ''}';
    case 'baseline':
      return 'Введены стартовые остатки: товаров ${after['products'] ?? '?'}';
    case 'history':
      return 'Очищена история: ${after['kind'] ?? ''}';
    default:
      return '${r.entity}: ${r.action}';
  }
}

class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final data = ref.watch(_auditProvider);
    return StockScaffold(
      title: 'Журнал действий',
      body: switch (data) {
        AsyncData(value: (final rows, final names)) when rows.isNotEmpty =>
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final r = rows[i];
              final who = r.staffId == null
                  ? 'общий PIN'
                  : (names[r.staffId] ?? 'удалённый сотрудник');
              final after = _after(r)['by'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(describeAudit(r),
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${fmtDate(r.at.toLocal())} · ${after ?? who}',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
              );
            },
          ),
        AsyncData() => const StockEmpty(
            icon: Icons.fact_check_outlined,
            title: 'Пока пусто',
            subtitle: 'Здесь появятся приёмки поставок и стартовые остатки '
                'с именем сотрудника. Записи нельзя изменить или удалить.',
          ),
        AsyncError(:final error) => Center(child: Text('Ошибка: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
