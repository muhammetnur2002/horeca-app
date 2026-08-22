/// Диалоги и фоновые действия вкладки "Приложение": выбор/удаление лого,
/// смена названия для отчётов, создание и восстановление бэкапа.
/// Вынесены из app_settings_tab.dart.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';

import 'package:horeca_app/features/backup/data/backup_service.dart';

Future<void> pickEstablishmentLogo(
    BuildContext context, SettingsRepository repo) async {
  final picker = ImagePicker();
  final picked =
      await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
  if (picked == null) return;
  // image_picker отдаёт файл во временном кэше, который система может
  // очистить в любой момент — копируем в постоянную папку приложения,
  // иначе лого может однажды "пропасть" само по себе.
  try {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = picked.path.split('.').last;
    final savedPath =
        '${docsDir.path}/establishment_logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(picked.path).copy(savedPath);
    repo.setLogoPath(savedPath);
  } catch (_) {
    // Если копирование не удалось — используем оригинальный путь,
    // чтобы хотя бы в текущей сессии лого отобразилось.
    repo.setLogoPath(picked.path);
  }
}

void showLogoOptions(
    BuildContext context, SettingsRepository repo, bool isDark, bool hasLogo) {
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.orange),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                pickEstablishmentLogo(context, repo);
              },
            ),
            if (hasLogo)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
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

void showEditEstablishmentNameDialog(BuildContext context, String currentName,
    SettingsRepository repo, AppLocalizations l10n, bool isDark) {
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
          prefixIcon:
              const Icon(Icons.storefront_outlined, color: AppColors.orange),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
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

Future<void> createAppBackup(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  try {
    await BackupService.shareBackup(prefs);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Не удалось создать бэкап',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

Future<void> restoreAppBackup(
    BuildContext context, WidgetRef ref, bool isDark) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Восстановить из бэкапа?',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text(
          'Текущие данные будут заменены данными из файла резервной копии.',
          style: TextStyle(color: AppColors.muted, fontSize: 14)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Отмена', style: TextStyle(color: AppColors.muted))),
        ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
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
  final success =
      await BackupService.restoreFromFile(result.files.single.path!, prefs);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          success
              ? 'Данные восстановлены. Перезапустите приложение'
              : 'Ошибка: неверный файл резервной копии',
          style: const TextStyle(color: Colors.white)),
      backgroundColor: success ? AppColors.green : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
