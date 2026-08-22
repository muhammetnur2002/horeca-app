/// Мелкие виджеты дашборда управляющего: карточка-подложка, строка
/// инсайта, карточка заведения. Вынесены из manager_dashboard_screen.dart.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_insights.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_models.dart';

/// Общая карточка-подложка со стеклянным эффектом (без блюра — тут он не
/// использовался и в оригинале).
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? accentColor;
  const GlassCard({super.key, required this.child, required this.isDark, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final a = accentColor;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: a != null
            ? a.withOpacity(isDark ? 0.08 : 0.05)
            : Colors.white.withOpacity(isDark ? 0.08 : 0.6),
        border: Border.all(
            color: a != null
                ? a.withOpacity(0.25)
                : Colors.white.withOpacity(isDark ? 0.12 : 0.8)),
      ),
      child: child,
    );
  }
}

/// Одна строка текстовой сводки ("СВОДКА ЗА НЕДЕЛЮ").
class InsightRow extends StatelessWidget {
  final Insight insight;
  final bool isDark;
  const InsightRow({super.key, required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(insight.icon, color: insight.color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            insight.text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточка одного заведения в списке "ПО ЗАВЕДЕНИЯМ".
class VenueCard extends StatelessWidget {
  final VenueSnapshot snapshot;
  final bool isDark;
  const VenueCard({super.key, required this.snapshot, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return GlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(snapshot.venue.code,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(snapshot.venue.name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
            if (snapshot.error == null)
              Text(formatDashboardMoney(snapshot.todayRevenue),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green)),
          ]),
          if (snapshot.error != null) ...[
            const SizedBox(height: 8),
            Text(snapshot.error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
          ] else ...[
            const SizedBox(height: 6),
            Text('Закрытий смены сегодня: ${snapshot.shiftsToday}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
