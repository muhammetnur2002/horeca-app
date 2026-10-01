import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/legacy_migration.dart';

enum RestoreResult { success, invalidFile, error }

/// Резервная копия всех данных устройства (все заведения).
///
/// Формат версии 2 — выгрузка таблиц локальной базы «как есть» (строки
/// SQL-таблиц). Файлы версии 1 (ключи SharedPreferences из старых версий
/// приложения) тоже восстанавливаются: ключи кладутся на место и
/// прогоняются через тот же перенос, что и при обновлении.
///
/// PIN-коды в бэкап сознательно не входят: файл пересылают через
/// мессенджеры, и это была бы утечка кода доступа.
class BackupService {
  static const _formatVersion = 2;

  /// Содержимое бэкапа — все таблицы базы.
  static Future<Map<String, dynamic>> exportData(AppDatabase db) async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in db.allTables) {
      final rows = await db
          .customSelect('SELECT * FROM "${table.actualTableName}"')
          .get();
      tables[table.actualTableName] = rows.map((r) => r.data).toList();
    }

    return <String, dynamic>{
      'app': 'Akyl',
      'version': _formatVersion,
      'schemaVersion': db.schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'tables': tables,
    };
  }

  static Future<String> createBackup(AppDatabase db) async {
    final backup = await exportData(db);
    final dir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${dir.path}/akyl_backup_$dateStr.json');
    await file.writeAsString(jsonEncode(backup));
    return file.path;
  }

  static Future<void> shareBackup(AppDatabase db) async {
    final path = await createBackup(db);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/json')],
      subject: 'Резервная копия Akyl',
    );
  }

  /// Полностью заменяет данные на устройстве данными из файла.
  /// После восстановления приложение нужно перезапустить.
  static Future<RestoreResult> restoreFromFile(
      String filePath, AppDatabase db, SharedPreferences prefs) async {
    final Map<String, dynamic> backup;
    try {
      backup = jsonDecode(await File(filePath).readAsString())
          as Map<String, dynamic>;
    } on FormatException {
      return RestoreResult.invalidFile;
    } catch (_) {
      return RestoreResult.error;
    }
    return importData(backup, db, prefs);
  }

  /// Заменяет данные на устройстве содержимым бэкапа (любой версии).
  static Future<RestoreResult> importData(Map<String, dynamic> backup,
      AppDatabase db, SharedPreferences prefs) async {
    if (backup['app'] != 'Akyl') return RestoreResult.invalidFile;
    try {
      if (backup['version'] == _formatVersion) {
        await _restoreTables(db, backup['tables'] as Map<String, dynamic>);
      } else {
        await _restoreLegacy(db, prefs, backup['data'] as Map<String, dynamic>);
      }
      return RestoreResult.success;
    } catch (_) {
      return RestoreResult.error;
    }
  }

  static Future<void> _restoreTables(
      AppDatabase db, Map<String, dynamic> tables) async {
    final known = {for (final t in db.allTables) t.actualTableName};
    await db.transaction(() async {
      for (final name in known) {
        await db.customStatement('DELETE FROM "$name"');
      }
      for (final entry in tables.entries) {
        // Таблицы из файла, которых нет в этой версии схемы, пропускаем.
        if (!known.contains(entry.key)) continue;
        for (final raw in entry.value as List) {
          final row = Map<String, Object?>.from(raw as Map);
          if (row.isEmpty) continue;
          final columns = row.keys.map((c) => '"$c"').join(', ');
          final placeholders = List.filled(row.length, '?').join(', ');
          await db.customStatement(
            'INSERT INTO "${entry.key}" ($columns) VALUES ($placeholders)',
            row.values.toList(),
          );
        }
      }
    });
  }

  /// Файл старого формата: ключи SharedPreferences.
  static Future<void> _restoreLegacy(AppDatabase db, SharedPreferences prefs,
      Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value as String);
      }
    }
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.customStatement('DELETE FROM "${table.actualTableName}"');
      }
    });
    await LegacyMigration.run(db: db, prefs: prefs, force: true);
  }
}
