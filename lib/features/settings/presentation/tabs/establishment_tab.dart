import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

final _currencies = [
  {'symbol': '₸', 'name': 'Тенге', 'flag': '🇰🇿'},
  {'symbol': '₽', 'name': 'Рубль', 'flag': '🇷🇺'},
  {'symbol': '\$', 'name': 'Доллар', 'flag': '🇺🇸'},
  {'symbol': '€', 'name': 'Евро', 'flag': '🇪🇺'},
  {'symbol': 'м', 'name': 'Манат', 'flag': '🇹🇲'},
  {'symbol': 'с', 'name': 'Сом', 'flag': '🇰🇬'},
];

mixin currency {
}

class EstablishmentTab extends ConsumerWidget {
  const EstablishmentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsRepositoryProvider);
    final name = settings.establishmentName;
    final currency = settings.currency;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
      child: Column(
        children: [
          // Карточка заведения
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
                ),
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.storefront_outlined,
                        size: 40, color: AppColors.orange)),
                  const SizedBox(height: 20),
                  Text(l10n.establishmentName,
                      style: const TextStyle(fontSize: 12,
                          color: AppColors.muted, fontWeight: FontWeight.w500,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(name, style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.w700, color: textColor,
                      letterSpacing: -0.5)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showEditDialog(context, name, repo, l10n, isDark),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.orange.withOpacity(0.15),
                            border: Border.all(
                                color: AppColors.orange.withOpacity(0.3))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_outlined,
                                  color: AppColors.orange, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.edit, style: const TextStyle(
                                  color: AppColors.orange, fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                            ])))),
                  ),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Выбор валюты
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.attach_money_rounded,
                            color: AppColors.green, size: 20)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Валюта', style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600, color: textColor)),
                        Text('Текущая: $currency',
                            style: const TextStyle(fontSize: 12,
                                color: AppColors.muted)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _currencies.map((c) {
                        final sym = c['symbol']!;
                        final selected = currency == sym;
                        return GestureDetector(
                          onTap: () => repo.setCurrency(sym),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: selected
                                  ? AppColors.orange.withOpacity(0.15)
                                  : Colors.white.withOpacity(
                                      isDark ? 0.05 : 0.5),
                              border: Border.all(
                                color: selected
                                    ? AppColors.orange
                                    : Colors.white.withOpacity(
                                        isDark ? 0.1 : 0.3),
                                width: selected ? 1.5 : 1,
                              )),
                            child: Row(mainAxisSize: MainAxisSize.min,
                                children: [
                              Text(c['flag']!, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sym, style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700,
                                      color: selected
                                          ? AppColors.orange
                                          : textColor)),
                                  Text(c['name']!, style: const TextStyle(
                                      fontSize: 10, color: AppColors.muted)),
                                ]),
                              if (selected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded,
                                    size: 16, color: AppColors.orange),
                              ],
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Инфо
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.green.withOpacity(isDark ? 0.08 : 0.05),
                  border: Border.all(color: AppColors.green.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.green, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Text(
                      'Название и валюта отображаются в PDF-отчётах',
                      style: TextStyle(fontSize: 13, color: AppColors.green))),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String currentName,
      dynamic repo, AppLocalizations l10n, bool isDark) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.establishmentName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.establishmentName,
            prefixIcon: const Icon(Icons.storefront_outlined,
                color: AppColors.orange)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: AppColors.muted))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                repo.setEstablishmentName(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text(l10n.save)),
        ],
      ),
    );
  }
}