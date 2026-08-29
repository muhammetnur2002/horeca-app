import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Результат восстановления — вместо голого bool, чтобы показать причину сбоя.
class RestoreResult {
  final bool success;
  final String message;
  const RestoreResult(this.success, this.message);
}

class BackupService {
  const BackupService._();

  static const int schemaVersion = 2;

  /// Что попадает в резервную копию.
  ///
  /// Намеренно НЕ включены `admin_pin_hash`, `staff_pin_hash`, `pin_salt`
  /// и настройки iiko: файл копии пересылается через мессенджеры, и коды
  /// доступа с ключом интеграции не должны его покидать.
  static const _keysToBackup = <String>[
    'settings_data',
    'history_data',
    'shift_records',
    'notification_data',
    'custom_inventory_template',
    'current_stock_levels',
  ];

  static Uint8List buildBackupBytes(SharedPreferences prefs) {
    final data = <String, String>{};
    for (final key in _keysToBackup) {
      final value = prefs.getString(key);
      if (value != null) data[key] = value;
    }
    final backup = <String, dynamic>{
      'app': 'Akyl',
      'schemaVersion': schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(backup)));
  }

  static Future<void> shareBackup(SharedPreferences prefs) async {
    final bytes = buildBackupBytes(prefs);
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/akyl_backup_$dateStr.json');
    await file.writeAsBytes(bytes);
    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Резервная копия Akyl',
      );
    } finally {
      // Временный файл раньше оставался в кеше навсегда.
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('BackupService: не удалось удалить временный файл: $e');
      }
    }
  }

  /// Восстанавливает данные из содержимого файла копии.
  ///
  /// Принимает байты, а не путь: file_picker на разных платформах отдаёт
  /// либо путь, либо только данные.
  static Future<RestoreResult> restoreFromBytes(
    Uint8List bytes,
    SharedPreferences prefs,
  ) async {
    Map<String, dynamic> backup;
    try {
      backup = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('BackupService: файл не является корректным JSON: $e');
      return const RestoreResult(false, 'Файл повреждён или не является копией Akyl');
    }

    if (backup['app'] != 'Akyl') {
      return const RestoreResult(false, 'Это не файл резервной копии Akyl');
    }

    final version = backup['schemaVersion'];
    if (version is int && version > schemaVersion) {
      return const RestoreResult(
          false, 'Копия создана более новой версией приложения');
    }

    final data = backup['data'];
    if (data is! Map) {
      return const RestoreResult(false, 'В копии нет данных');
    }

    var restored = 0;
    for (final key in _keysToBackup) {
      final value = data[key];
      if (value is String) {
        await prefs.setString(key, value);
        restored++;
      }
    }

    if (restored == 0) {
      return const RestoreResult(false, 'В копии не оказалось известных данных');
    }
    return RestoreResult(true, 'Восстановлено разделов: $restored');
  }
}
