import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const _keysToBackup = [
    'settings_data',
    'history_data',
    'shift_records',
    'notification_data',
  ];

  static Future<String> createBackup(SharedPreferences prefs) async {
    final Map<String, dynamic> backup = {
      'app': 'Akyl',
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'data': {},
    };

    for (final key in _keysToBackup) {
      final value = prefs.getString(key);
      if (value != null) {
        backup['data'][key] = value;
      }
    }

    final jsonString = jsonEncode(backup);
    final dir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${dir.path}/akyl_backup_$dateStr.json');
    await file.writeAsString(jsonString);
    return file.path;
  }

  static Future<void> shareBackup(SharedPreferences prefs) async {
    final path = await createBackup(prefs);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/json')],
      subject: 'Резервная копия Akyl',
    );
  }

  static Future<bool> restoreFromFile(String filePath, SharedPreferences prefs) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final backup = jsonDecode(content) as Map<String, dynamic>;

      if (backup['app'] != 'Akyl') {
        throw Exception('Это не файл резервной копии Akyl');
      }

      final data = backup['data'] as Map<String, dynamic>;
      for (final key in _keysToBackup) {
        if (data.containsKey(key)) {
          await prefs.setString(key, data[key] as String);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}