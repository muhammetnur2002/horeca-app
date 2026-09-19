/// Блок "Аккаунт" на вкладке "Приложение": вход/выход, синхронизация,
/// переход в дашборд управляющего. Вынесен из app_settings_tab.dart —
/// у него собственное состояние (индикатор синхронизации), поэтому это
/// самостоятельный StatefulWidget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/account/presentation/account_gate_screen.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_widgets.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/features/venue/presentation/manager_dashboard_screen.dart';

class AccountSection extends ConsumerStatefulWidget {
  final bool isDark;
  const AccountSection({super.key, required this.isDark});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    final uid = ref.read(accountRepositoryProvider).uid;
    if (uid == null) return;
    setState(() => _isSyncing = true);
    final prefs = ref.read(sharedPreferencesProvider);
    final venueCode = ref.read(venueRepositoryProvider).activeVenueCode;
    final registryOk = await CloudSyncService.pushVenueRegistry(
        uid, ref.read(venueRepositoryProvider).venues);
    final dataOk = await CloudSyncService.pushToCloud(uid, prefs, venueCode);
    // Раньше здесь всегда показывалось "Данные отправлены", даже если оба
    // вызова выше молча падали (например, нет сети) — сотрудник считал
    // данные синхронизированными, хотя они оставались только на устройстве.
    final success = registryOk && dataOk;
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Данные отправлены в облако'
            : 'Не удалось синхронизировать — проверьте интернет'),
        backgroundColor: success ? null : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _logout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выйти из аккаунта?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
            'Локальные данные на этом устройстве останутся, но перестанут '
            'синхронизироваться, пока вы не войдёте снова.',
            style: TextStyle(color: AppColors.muted, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(l10n.cancel, style: const TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(accountRepositoryProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountRepositoryProvider);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);

    if (!accountState.isLoggedIn) {
      return AboutRow(
        icon: Icons.cloud_outlined,
        title: 'Войти в аккаунт',
        subtitle: 'Синхронизируйте данные между устройствами',
        color: AppColors.orange,
        isDark: widget.isDark,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountGateScreen(onSkip: () => Navigator.pop(context)),
            )),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(widget.isDark ? 0.06 : 0.6),
          border: Border.all(
              color: Colors.white.withOpacity(widget.isDark ? 0.1 : 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.cloud_done_outlined,
                      color: AppColors.green, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(accountState.email ?? '',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 2),
                    const Text('Синхронизация включена',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ])),
            ]),
            if (!accountState.emailVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.mark_email_unread_outlined,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Email не подтверждён',
                          style: TextStyle(fontSize: 12, color: textColor))),
                  TextButton(
                    onPressed: () async {
                      final notifier = ref.read(accountRepositoryProvider.notifier);
                      await notifier.resendVerificationEmail();
                      await notifier.refreshEmailVerified();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Письмо отправлено повторно'),
                            behavior: SnackBarBehavior.floating));
                      }
                    },
                    child: const Text('Отправить снова',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ManagerDashboardScreen())),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: AppColors.orange.withOpacity(0.12),
                  foregroundColor: AppColors.orange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('Дашборд управляющего',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSyncing ? null : _syncNow,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: BorderSide(color: AppColors.muted.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Синхронизировать',
                          style: TextStyle(color: textColor, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Выйти',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
