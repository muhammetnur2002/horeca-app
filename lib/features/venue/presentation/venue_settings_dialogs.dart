/// Диалоги экрана "Заведения": добавление, переименование, удаление (с
/// подтверждением PIN-ом или паролем аккаунта). Вынесены из
/// venue_settings_screen.dart, чтобы не раздувать его build().
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

void showAddVenueDialog(BuildContext context, WidgetRef ref, bool isDark) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  final repo = ref.read(venueRepositoryProvider.notifier);
  final nextCode = repo.nextFreeCode;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Новое заведение (код $nextCode)',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Название заведения',
          prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.orange),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted))),
        ElevatedButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              repo.addVenue(ctrl.text.trim());
              Navigator.pop(ctx);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Создать'),
        ),
      ],
    ),
  );
}

void showRenameVenueDialog(BuildContext context, WidgetRef ref, Venue venue, bool isDark) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController(text: venue.name);
  final repo = ref.read(venueRepositoryProvider.notifier);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Заведение ${venue.code}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Название заведения',
          prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.orange),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted))),
        ElevatedButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              repo.renameVenue(venue.code, ctrl.text.trim());
              Navigator.pop(ctx);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

/// Удаление заведения — разрушительное действие, поэтому требует
/// подтверждения либо PIN-кодом администратора ИМЕННО этого заведения,
/// либо паролем от облачного аккаунта (управляющий). Одно поле ввода —
/// проверяем оба варианта, чтобы не заставлять человека выбирать способ
/// вручную.
void showDeleteVenueDialog(BuildContext context, WidgetRef ref, Venue venue, bool isDark) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  bool obscure = true;
  bool isChecking = false;
  String? error;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Удалить «${venue.name}»?',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Все данные этого заведения (товары, история, отчёты) будут '
              'удалены безвозвратно — с этого устройства и из облака. '
              'Подтвердите PIN-кодом администратора этого заведения или '
              'паролем от аккаунта.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              obscureText: obscure,
              autofocus: true,
              enabled: !isChecking,
              decoration: InputDecoration(
                hintText: 'PIN администратора или пароль аккаунта',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.orange),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: isChecking ? null : () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: isChecking
                ? null
                : () async {
                    final input = ctrl.text.trim();
                    if (input.isEmpty) return;
                    setState(() {
                      isChecking = true;
                      error = null;
                    });

                    final pinOk =
                        await AuthRepository.checkAdminPinForVenue(venue.code, input);
                    final passwordOk = pinOk
                        ? false
                        : await ref
                            .read(accountRepositoryProvider.notifier)
                            .verifyPassword(input);

                    if (!(pinOk || passwordOk)) {
                      setState(() {
                        isChecking = false;
                        error = 'Неверный PIN или пароль';
                      });
                      return;
                    }

                    final venueRepo = ref.read(venueRepositoryProvider.notifier);
                    final deleted = await venueRepo.deleteVenue(venue.code);
                    final uid = ref.read(accountRepositoryProvider).uid;
                    if (deleted && uid != null) {
                      await CloudSyncService.deleteVenueCloud(uid, venue.code);
                      await CloudSyncService.pushVenueRegistry(
                          uid, ref.read(venueRepositoryProvider).venues);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(deleted
                            ? '«${venue.name}» удалено'
                            : 'Не удалось удалить заведение'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.delete),
          ),
        ],
      ),
    ),
  );
}
