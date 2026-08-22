/// Вкладка "Приложение" в Настройках: лого/название заведения, аккаунт,
/// тема, валюта, десерты на закрытии смены, бэкап и переходы в
/// уведомления / свой шаблон PDF / FAQ / о программе.
///
/// Сама вкладка только собирает готовые блоки — вся вёрстка и логика
/// разнесены по app_settings_account_section.dart, app_settings_theme_card.dart,
/// app_settings_currency_card.dart, app_settings_widgets.dart и
/// app_settings_dialogs.dart, чтобы этот файл не превращался в стену кода.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/custom_template/presentation/template_screen.dart';
import 'package:horeca_app/features/notifications/presentation/notifications_screen.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/presentation/about_screen.dart';
import 'package:horeca_app/features/settings/presentation/faq_screen.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_account_section.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_currency_card.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_dialogs.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_theme_card.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_widgets.dart';
import 'package:horeca_app/features/venue/presentation/venue_settings_screen.dart';

class AppSettingsTab extends ConsumerWidget {
  const AppSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final settings = ref.watch(settingsRepositoryProvider);
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 130, 16, 24),
      children: [
        const SizedBox(height: 16),
        AppThemeCard(
          themeMode: themeMode,
          isDark: isDark,
          onSetThemeMode: (mode) =>
              ref.read(themeModeProvider.notifier).setThemeMode(mode),
        ),
        const SizedBox(height: 16),
        AccountSection(isDark: isDark),
        const SizedBox(height: 16),
        AppCurrencyCard(
          currency: settings.currency,
          isDark: isDark,
          onSelect: (symbol) => repo.setCurrency(symbol),
        ),
        const SizedBox(height: 12),
        DessertsToggleCard(
          value: settings.showShiftDesserts,
          isDark: isDark,
          onChanged: (v) => repo.setShowShiftDesserts(v),
        ),
        const SizedBox(height: 16),
        SettingsNavCard(
          icon: Icons.notifications_outlined,
          title: 'Уведомления',
          subtitle: 'Напоминания об инвентаризации и остатках',
          color: AppColors.orange,
          isDark: isDark,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        const SizedBox(height: 10),
        SettingsNavCard(
          icon: Icons.description_outlined,
          title: 'Свой шаблон PDF',
          subtitle: 'Загрузите Excel-файл, чтобы настроить отчёт под себя',
          color: const Color(0xFF378ADD),
          isDark: isDark,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TemplateScreen())),
        ),
        const SizedBox(height: 10),
        SettingsNavCard(
          icon: Icons.storefront_outlined,
          title: 'Заведения',
          subtitle:
              'До 5 заведений на аккаунт, PIN-коды администратора и сотрудников',
          color: AppColors.green,
          isDark: isDark,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VenueSettingsScreen())),
        ),
        const SizedBox(height: 16),
        SettingsInfoBanner(
          text: 'Резервная копия сохраняет товары, категории, сотрудников '
              'и настройки — восстановить её можно на другом устройстве.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => createAppBackup(context, ref),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                side: BorderSide(color: AppColors.muted.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text('Создать бэкап',
                  style: TextStyle(color: textColor, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => restoreAppBackup(context, ref, isDark),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                side: BorderSide(color: AppColors.muted.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text('Восстановить',
                  style: TextStyle(color: textColor, fontSize: 13)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        AboutRow(
          icon: Icons.help_outline_rounded,
          title: 'Частые вопросы',
          subtitle: 'Ответы на частые вопросы об использовании приложения',
          color: AppColors.green,
          isDark: isDark,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const FaqScreen())),
        ),
        const SizedBox(height: 10),
        AboutRow(
          icon: Icons.info_outline_rounded,
          title: 'О программе',
          subtitle: 'Версия, юридические документы, сброс данных',
          color: AppColors.muted,
          isDark: isDark,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
      ],
    );
  }
}
