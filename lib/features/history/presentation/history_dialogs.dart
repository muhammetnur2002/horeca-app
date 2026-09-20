/// Нижний лист с полным текстом записи истории. Вынесен из
/// history_screen.dart, чтобы не раздувать его build().
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:share_plus/share_plus.dart';

void showHistoryDetail(BuildContext ctx, HistoryEntry e) {
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    padding: const EdgeInsets.all(24),
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
