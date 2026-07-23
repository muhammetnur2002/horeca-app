import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/notifications/presentation/notifications_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:horeca_app/features/backup/data/backup_service.dart';
import 'package:horeca_app/app/di.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:horeca_app/features/custom_template/presentation/template_screen.dart';

final _currencies = [
  {'symbol': '₸', 'name': 'Тенге', 'flag': '🇰🇿'},
  {'symbol': '₽', 'name': 'Рубль', 'flag': '🇷🇺'},
  {'symbol': '\$', 'name': 'Доллар', 'flag': '🇺🇸'},
  {'symbol': '€', 'name': 'Евро', 'flag': '🇪🇺'},
  {'symbol': 'м', 'name': 'Манат', 'flag': '🇹🇲'},
  {'symbol': 'с', 'name': 'Сом', 'flag': '🇰🇬'},
];

class EstablishmentTab extends ConsumerWidget {
  const EstablishmentTab({super.key});

  Future<void> _pickLogo(BuildContext context, dynamic repo) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      repo.setLogoPath(picked.path);
    }
  }

  void _showLogoOptions(BuildContext context, dynamic repo, bool isDark, bool hasLogo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.orange),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickLogo(context, repo);
                },
              ),
              if (hasLogo)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Удалить лого'),
                  onTap: () {
                    Navigator.pop(context);
                    repo.removeLogo();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsRepositoryProvider);
    final name = settings.establishmentName;
    final currency = settings.currency;
    final logoPath = settings.logoPath;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final hasLogo = logoPath != null && File(logoPath).existsSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 130, 20, 20),
      child: Column(
        children: [
          // Карточка заведения
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  // Лого / иконка с кнопкой +
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => _showLogoOptions(context, repo, isDark, hasLogo),
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasLogo
                              ? Image.file(File(logoPath), fit: BoxFit.cover,
                                  width: 80, height: 80)
                              : const Icon(Icons.storefront_outlined,
                                  size: 40, color: AppColors.orange),
                        ),
                      ),
                      Positioned(
                        right: -4, bottom: -4,
                        child: GestureDetector(
                          onTap: () => _showLogoOptions(context, repo, isDark, hasLogo),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  width: 2)),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

// Резервное копирование
Row(children: [
  Expanded(child: GestureDetector(
    onTap: () => _createBackup(context, ref),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.green.withOpacity(0.12),
            border: Border.all(color: AppColors.green.withOpacity(0.3))),
          child: Column(children: [
            const Icon(Icons.cloud_upload_outlined, color: AppColors.green, size: 22),
            const SizedBox(height: 6),
            Text('Создать бэкап', style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ),
  )),
  const SizedBox(width: 10),
  Expanded(child: GestureDetector(
    onTap: () => _restoreBackup(context, ref, isDark),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.orange.withOpacity(0.12),
            border: Border.all(color: AppColors.orange.withOpacity(0.3))),
          child: Column(children: [
            const Icon(Icons.cloud_download_outlined, color: AppColors.orange, size: 22),
            const SizedBox(height: 6),
            Text('Восстановить', style: const TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ),
  )),
]),

const SizedBox(height: 16),

// Уведомления

        // Уведомления
GestureDetector(
  onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => const NotificationsScreen())),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_active_outlined, color: AppColors.green, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Настройка уведомлений', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            Text('Напоминания о заказе и инвентаризации', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted.withOpacity(0.5)),
        ]),
      ),
    ),
  ),
),
const SizedBox(height: 10),

// Свой шаблон PDF
GestureDetector(
  onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => const TemplateScreen())),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFF378ADD).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.table_chart_outlined, color: Color(0xFF378ADD), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Свой шаблон PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            Text('Загрузите Excel-файл для инвентаризации', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted.withOpacity(0.5)),
        ]),
      ),
    ),
  ),
),
const SizedBox(height: 16),

// Инфо
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
            'Название, валюта и лого отображаются в PDF-отчётах',
            style: TextStyle(fontSize: 13, color: AppColors.green))),
      ]),
    ),
  ),
),
        ],
      ),
    );
  }

  void _createBackup(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  try {
    await BackupService.shareBackup(prefs);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Не удалось создать бэкап', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

void _restoreBackup(BuildContext context, WidgetRef ref, bool isDark) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Восстановить из бэкапа?', style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text(
          'Текущие данные будут заменены данными из файла резервной копии.',
          style: TextStyle(color: AppColors.muted, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.muted))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Восстановить')),
      ],
    ),
  );
  if (confirm != true) return;

  final result = await fp.FilePicker.platform.pickFiles(
    type: fp.FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.single.path == null) return;

  final prefs = ref.read(sharedPreferencesProvider);
  final success = await BackupService.restoreFromFile(result.files.single.path!, prefs);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Данные восстановлены. Перезапустите приложение' : 'Ошибка: неверный файл резервной копии',
          style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? AppColors.green : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }
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




