import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class ThemeTab extends ConsumerWidget {
  const ThemeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            themeMode == ThemeMode.dark ? Icons.nightlight_round : Icons.wb_sunny,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('theme') ?? 'Тема',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text(l10n.translate('darkTheme') ?? 'Тёмная тема'),
            subtitle: Text(themeMode == ThemeMode.dark
                ? (l10n.translate('darkThemeOn') ?? 'Включена')
                : (l10n.translate('lightThemeOn') ?? 'Выключена')),
            value: themeMode == ThemeMode.dark,
            onChanged: (isDark) {
              notifier.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
            ),
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}