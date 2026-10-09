import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/core/pdf_generator/pdf_saver.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

enum RestoreResult { success, invalidFile, error }

class BackupService {
  // Ключи, которые ведутся отдельно на каждое заведение (см.
  // venueKeySuffix). У заведения "01" суффикс пустой, поэтому старые
  // бэкапы с ключом notification_data по-прежнему попадают в него.
  static const _perVenueKeys = [
    'settings_data',
    'history_data',
    'shift_records',
    'notification_data',
    'current_stock_levels',
    'custom_inventory_template',
    'shift_draft',
    'supply_requests',
    'goods_receipts',
    'stock_moves',
    'ocr_quota',
  ];

  // Глобальные ключи (одни на всё устройство, не по заведениям).
  static const _globalKeys = [
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
      'version': '1.1.0',
      'createdAt': DateTime.now().toIso8601String(),
      'data': data,
    };

    return jsonEncode(backup);
  }

  static Future<void> shareBackup(SharedPreferences prefs) async {
    final jsonString = await createBackup(prefs);
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    await saveFile(
      Uint8List.fromList(utf8.encode(jsonString)),
      'akyl_backup_$dateStr.json',
      mimeType: 'application/json',
    );
  }

  static Future<RestoreResult> restoreFromContent(
      String content, SharedPreferences prefs) async {
    try {
      final backup = jsonDecode(content) as Map<String, dynamic>;

      if (backup['app'] != 'Akyl') {
        return RestoreResult.invalidFile;
      }

      final data = backup['data'] as Map<String, dynamic>;
      // Восстанавливаем всё, что есть в файле, каким бы ни был набор
      // ключей (старые бэкапы — только заведение "01", новые — все сразу).
      for (final entry in data.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value as String);
        }
      }
      return RestoreResult.success;
    } on FormatException {
      // Файл не в формате JSON вообще — точно не наш бэкап.
      return RestoreResult.invalidFile;
    } catch (e) {
      // Любая другая ошибка (нет доступа к файлу, повреждённые данные
      // внутри валидного JSON и т.п.) — это не обязательно "неверный
      // файл", поэтому раньше вводящее в заблуждение сообщение теперь
      // разделено на два разных случая (см. RestoreResult).
      return RestoreResult.error;
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
