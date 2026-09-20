/// Форматирование денег и генерация текстовых инсайтов для дашборда
/// управляющего. Вынесено из manager_dashboard_screen.dart.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_models.dart';

/// Форматирует сумму с разделением разрядов пробелом: 12000 -> "12 000".
String formatDashboardMoney(double v) {
  if (v == 0) return '0';
  return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}

/// Превращает сухие цифры (выручка за неделю, списания по товарам) в
/// короткие фразы обычным языком — чтобы управляющий за 5 секунд понял,
/// на что обратить внимание, не разглядывая таблицы. Чистая функция без
/// побочных эффектов, поэтому её легко проверить отдельно от Firestore.
List<Insight> generateDashboardInsights({
  required double weekRevenue,
  required double prevWeekRevenue,
  required Map<String, int> weekWriteOffs,
  required Map<String, int> prevWeekWriteOffs,
}) {
  final insights = <Insight>[];

  // ── Выручка за неделю к предыдущей ──────────────────────────────────────
  if (prevWeekRevenue > 0) {
    final pct = ((weekRevenue - prevWeekRevenue) / prevWeekRevenue) * 100;
    if (pct.abs() >= 5) {
      final rounded = pct.abs().round();
      if (pct > 0) {
        insights.add(Insight(
          text: 'Выручка за неделю выросла на $rounded% к прошлой неделе — хороший темп.',
          icon: Icons.trending_up_rounded,
          color: AppColors.green,
        ));
      } else {
        insights.add(Insight(
          text: 'Выручка за неделю упала на $rounded% к прошлой неделе — стоит обратить внимание.',
          icon: Icons.trending_down_rounded,
          color: Colors.redAccent,
        ));
      }
    }
  }

  // ── Резкий рост списаний по конкретным товарам ──────────────────────────
  // Считаем подозрительным, только если рост существенный и не на пустом
  // месте (иначе "было 1, стало 2" будет ложно кричать "+100%").
  final spikes = <MapEntry<String, double>>[]; // ключ -> "вес" для сортировки
  weekWriteOffs.forEach((name, weekQty) {
    final prevQty = prevWeekWriteOffs[name] ?? 0;
    if (prevQty >= 2) {
      final pct = ((weekQty - prevQty) / prevQty) * 100;
      if (pct >= 30 && (weekQty - prevQty) >= 2) {
        spikes.add(MapEntry(
            '«$name»: списания выросли на ${pct.round()}% '
            '(было $prevQty, стало $weekQty) — возможно, стоит проверить '
            'дозировку, порчу или учёт.',
            (weekQty - prevQty).toDouble()));
      }
    } else if (prevQty == 0 && weekQty >= 3) {
      spikes.add(MapEntry(
          '«$name»: на прошлой неделе списаний почти не было, а на этой — '
          '$weekQty шт. Стоит обратить внимание.',
          weekQty.toDouble()));
    }
  });
  spikes.sort((a, b) => b.value.compareTo(a.value));
  for (final s in spikes.take(3)) {
    insights.add(Insight(
      text: s.key,
      icon: Icons.warning_amber_rounded,
      color: Colors.orangeAccent,
    ));
  }

  if (insights.isEmpty) {
    insights.add(const Insight(
      text: 'Заметных отклонений за неделю нет — показатели в норме.',
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.green,
    ));
  }

  return insights;
}
