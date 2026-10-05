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
import 'package:horeca_app/features/settings/presentation/gemini_settings_screen.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_account_section.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_currency_card.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_dialogs.dart';
import 'package:horeca_app/features/settings/presentation/tabs/app_settings_theme_card.dart';
import 'package:horeca_app/shared/widgets/orbit_kit.dart';
import 'package:horeca_app/features/venue/presentation/venue_settings_screen.dart';

class AppSettingsTab extends ConsumerWidget {
  const AppSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsRepositoryProvider);
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(paletteProvider);

    final features = <(IconData, Color, String, String, Widget)>[
      (Icons.notifications_outlined, AppColors.orange, 'Уведомления',
          'Напоминания об инвентаризации и остатках', const NotificationsScreen()),
      (Icons.document_scanner_outlined, AppColors.accent3,
          'Распознавание накладных', 'Gemini 2.5 Flash читает накладные и чеки',
          const GeminiSettingsScreen()),
      (Icons.description_outlined, AppColors.green, 'Свой шаблон PDF',
          'Excel-шаблон для отчёта инвентаризации', const TemplateScreen()),
    ];
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 130, 16, 24),
      children: [
        const SizedBox(height: 8),
        AppThemeCard(
          themeMode: themeMode,
          isDark: isDark,
          onSetThemeMode: (mode) =>
              ref.read(themeModeProvider.notifier).setThemeMode(mode),
          palette: palette,
          onSetPalette: (p) =>
              ref.read(paletteProvider.notifier).setPalette(p),
        ),
        const SizedBox(height: 16),
        const OrbitSectionLabel('Аккаунт'),
        AccountSection(isDark: isDark),
        const SizedBox(height: 16),
        const OrbitSectionLabel('Заведение'),
        OrbitGroup(children: [
          OrbitRow(
            icon: Icons.storefront_outlined,
            iconColor: AppColors.orange,
            title: settings.establishmentName,
            subtitle: 'Название в заявках и отчётах',
            onTap: () => showEditEstablishmentNameDialog(context,
                settings.establishmentName, repo, AppLocalizations.of(context), isDark),
          ),
          OrbitRow(
            icon: Icons.store_mall_directory_outlined,
            iconColor: AppColors.green,
            title: 'Заведения и PIN',
            subtitle: 'До 5 заведений, PIN администратора и сотрудников',
            onTap: () => open(const VenueSettingsScreen()),
          ),
          OrbitRow(
            icon: Icons.cake_outlined,
            iconColor: AppColors.accent3,
            title: 'Десерты на закрытии смены',
            subtitle: settings.showShiftDesserts
                ? 'Шаги «витрина / склад / списания» показываются'
                : 'Скрыты — только смена и ручные списания',
            trailing: Switch(
              value: settings.showShiftDesserts,
              onChanged: (v) => repo.setShowShiftDesserts(v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        AppCurrencyCard(
          currency: settings.currency,
          isDark: isDark,
          onSelect: (symbol) => repo.setCurrency(symbol),
        ),
        const SizedBox(height: 16),
        const OrbitSectionLabel('Функции'),
        OrbitGroup(children: [
          for (final (icon, color, title, sub, screen) in features)
            OrbitRow(
              icon: icon,
              iconColor: color,
              title: title,
              subtitle: sub,
              onTap: () => open(screen),
            ),
        ]),
        const SizedBox(height: 16),
        const OrbitSectionLabel('Данные'),
        OrbitGroup(children: [
          OrbitRow(
            icon: Icons.upload_outlined,
            iconColor: AppColors.green,
            title: 'Создать бэкап',
            subtitle: 'Товары, сотрудники, история и учёт — файлом',
            onTap: () => createAppBackup(context, ref),
          ),
          OrbitRow(
            icon: Icons.download_outlined,
            iconColor: AppColors.orange,
            title: 'Восстановить из бэкапа',
            subtitle: 'Заменит данные на этом устройстве',
            onTap: () => restoreAppBackup(context, ref, isDark),
          ),
        ]),
        const SizedBox(height: 16),
        const OrbitSectionLabel('О приложении'),
        OrbitGroup(children: [
          OrbitRow(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.green,
            title: 'Частые вопросы',
            onTap: () => open(const FaqScreen()),
          ),
          OrbitRow(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.muted,
            title: 'О программе',
            subtitle: 'Версия, документы, сброс данных',
            onTap: () => open(const AboutScreen()),
          ),
        ]),
      ],
    );
  }
}
