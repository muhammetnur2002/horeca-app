import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

class BackupService {
  // Ключи, которые ведутся отдельно на каждое заведение (см.
  // venueKeySuffix) — при бэкапе к каждому добавляется суффикс кода
  // заведения. 'notification_data' сюда не входит — это единый глобальный
  // ключ на всё устройство, не привязанный к конкретному заведению.
  static const _perVenueKeys = [
    'settings_data',
    'history_data',
    'shift_records',
  ];

  // Глобальные ключи (одни на всё устройство, не по заведениям).
  static const _globalKeys = [
    'notification_data',
    'venues_list',
    'active_venue_code',
  ];

  /// PIN-коды сюда сознательно не входят: они хранятся в зашифрованном
  /// secure storage, а не в SharedPreferences, и включение их в файл
  /// бэкапа (который пользователь потом пересылает через WhatsApp/Telegram)
  /// было бы утечкой кода доступа. После восстановления бэкапа PIN нужно
  /// будет задать заново в Настройках.
  static Future<String> createBackup(SharedPreferences prefs) async {
    final Map<String, dynamic> data = {};

    for (final key in _globalKeys) {
      final value = prefs.getString(key);
      if (value != null) data[key] = value;
    }

    // Бэкапим данные КАЖДОГО заведения, а не только активного — иначе при
    // восстановлении на новом устройстве все заведения, кроме первого,
    // молча теряются.
    final codes = _venueCodesFromPrefs(prefs);
    for (final code in codes) {
      final suffix = venueKeySuffix(code);
      for (final key in _perVenueKeys) {
        final value = prefs.getString('$key$suffix');
        if (value != null) data['$key$suffix'] = value;
      }
    }

    final Map<String, dynamic> backup = {
      'app': 'Akyl',
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'data': data,
    };

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

  static Future<bool> restoreFromFile(
      String filePath, SharedPreferences prefs) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final backup = jsonDecode(content) as Map<String, dynamic>;

      if (backup['app'] != 'Akyl') {
        throw Exception('Это не файл резервной копии Akyl');
      }

      final data = backup['data'] as Map<String, dynamic>;
      // Восстанавливаем всё, что есть в файле, каким бы ни был набор
      // ключей (старые бэкапы — только заведение "01", новые — все сразу).
      for (final entry in data.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value as String);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Коды заведений, которые реально существуют на этом устройстве.
  /// Читаем 'venues_list' напрямую из SharedPreferences (а не через
  /// VenueRepository), чтобы бэкап не зависел от Riverpod-контекста —
  /// если список повреждён/отсутствует, считаем, что есть только "01"
  /// (устройства без мультизаведений).
  static List<String> _venueCodesFromPrefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString('venues_list');
      if (raw == null) return const ['01'];
      final list = jsonDecode(raw) as List;
      final codes = list
          .map((e) => (e as Map<String, dynamic>)['code'] as String?)
          .whereType<String>()
          .toList();
      return codes.isEmpty ? const ['01'] : codes;
    } catch (_) {
      return const ['01'];
    }
  }
}
