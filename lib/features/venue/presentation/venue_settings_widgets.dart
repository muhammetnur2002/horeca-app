/// Строка одного заведения в списке экрана "Заведения". Вынесена из
/// venue_settings_screen.dart, чтобы не раздувать его build().
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

class VenueRow extends StatelessWidget {
  final Venue venue;
  final bool isActive;
  final bool canDelete;
  final bool isDark;
  final VoidCallback onRename;
  final VoidCallback onSetupPin;
  final VoidCallback onDelete;

  const VenueRow({
    super.key,
    required this.venue,
    required this.isActive,
    required this.canDelete,
    required this.isDark,
    required this.onRename,
    required this.onSetupPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isActive
            ? AppColors.orange.withOpacity(0.12)
            : Colors.white.withOpacity(isDark ? 0.06 : 0.55),
        border: Border.all(
          color: isActive
              ? AppColors.orange.withOpacity(0.4)
              : Colors.white.withOpacity(isDark ? 0.1 : 0.8),
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onRename,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(venue.code,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.orange, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onRename,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                if (isActive) ...[
                  const SizedBox(height: 2),
                  const Text('Сейчас открыто',
                      style: TextStyle(fontSize: 11, color: AppColors.orange)),
                ],
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.pin_outlined, color: AppColors.orange, size: 20),
          tooltip: 'Задать PIN-коды',
          onPressed: onSetupPin,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: canDelete ? Colors.redAccent : AppColors.muted.withOpacity(0.4),
              size: 20),
          tooltip: canDelete
              ? 'Удалить заведение'
              : 'Нельзя удалить последнее заведение',
          onPressed: canDelete ? onDelete : null,
        ),
      ]),
    );
  }
}
