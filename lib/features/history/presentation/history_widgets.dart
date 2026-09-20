/// Карточка одной записи истории (заявка/инвентаризация) в списке.
/// Вынесена из history_screen.dart, чтобы не раздувать его build().
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';

class HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onTap;

  const HistoryCard({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onShare,
    required this.onTap,
  });

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
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
