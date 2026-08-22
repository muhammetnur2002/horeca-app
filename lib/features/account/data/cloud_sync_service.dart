import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Синхронизирует локальные данные с Firestore, привязывая их к uid
/// владельца аккаунта.
///
/// Структура в облаке:
///   businesses/{uid}                     — реестр заведений (код+название)
///   businesses/{uid}/venues/{code}        — данные конкретного заведения
///                                           (те же JSON-строки, что и раньше,
///                                           просто по одному документу на
///                                           заведение вместо одного на весь
///                                           аккаунт)
class CloudSyncService {
  static const _syncKeys = [
    'settings_data',
    'history_data',
    'shift_records',
    'notification_data',
  ];

  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _rootDoc(String uid) =>
      _db.collection('businesses').doc(uid);

  static DocumentReference<Map<String, dynamic>> _venueDoc(String uid, String code) =>
      _rootDoc(uid).collection('venues').doc(code);

  static String _lastKnownKey(String code) => 'cloud_sync_last_known_update_ms${venueKeySuffix(code)}';

  // ── Реестр заведений ────────────────────────────────────────────────────

  /// Отправляет список заведений (код+название) в облако — чтобы при входе
  /// с другого устройства приложение знало, какие заведения вообще есть,
  /// прежде чем скачивать данные каждого из них.
  static Future<void> pushVenueRegistry(String uid, List<Venue> venues) async {
    try {
      await _rootDoc(uid).set({
        'venues': venues.map((v) => v.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Нет сети — реестр просто не обновится, приложение продолжает работать.
    }
  }

  /// Скачивает список заведений из облака (null, если ещё ничего не отправляли
  /// или нет сети).
  static Future<List<Venue>?> pullVenueRegistry(String uid) async {
    try {
      final snap = await _rootDoc(uid).get();
      final data = snap.data();
      if (data == null || data['venues'] == null) return null;
      final list = data['venues'] as List;
      return list
          .map((e) => Venue.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── Данные одного заведения ─────────────────────────────────────────────

  /// true, если в облаке уже есть сохранённые данные для этого заведения.
  static Future<bool> hasCloudData(String uid, String venueCode) async {
    try {
      final snap = await _venueDoc(uid, venueCode).get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  /// Скачивает данные заведения из облака и перезаписывает ими локальное
  /// хранилище (с учётом суффикса ключей этого заведения).
  static Future<bool> pullToLocal(
      String uid, SharedPreferences prefs, String venueCode) async {
    try {
      final snap = await _venueDoc(uid, venueCode).get();
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;
      final suffix = venueKeySuffix(venueCode);
      for (final key in _syncKeys) {
        final value = data[key];
        if (value is String) {
          await prefs.setString('$key$suffix', value);
        }
      }
      await _rememberCloudUpdatedAt(prefs, venueCode, data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Отправляет текущие локальные данные заведения в облако (сливает с уже
  /// сохранёнными).
  static Future<void> pushToCloud(
      String uid, SharedPreferences prefs, String venueCode) async {
    try {
      final suffix = venueKeySuffix(venueCode);
      final Map<String, dynamic> payload = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      for (final key in _syncKeys) {
        final value = prefs.getString('$key$suffix');
        if (value != null) payload[key] = value;
      }
      await _venueDoc(uid, venueCode).set(payload, SetOptions(merge: true));
      // Перечитываем документ, чтобы узнать реальное серверное время записи
      // (FieldValue.serverTimestamp() не резолвится в локальном payload).
      final snap = await _venueDoc(uid, venueCode).get();
      final data = snap.data();
      if (data != null) await _rememberCloudUpdatedAt(prefs, venueCode, data);
    } catch (_) {
      // Отсутствие сети не должно ронять приложение — просто не синхронизируем.
    }
  }

  /// "Умная" синхронизация для периодического автосинка одного заведения:
  /// если в облаке за это время появились изменения с другого устройства
  /// (updatedAt новее, чем последний известный этому устройству) — сначала
  /// подтягиваем их локально, и только потом отправляем свежий локальный
  /// снимок обратно.
  static Future<void> syncSmart(
      String uid, SharedPreferences prefs, String venueCode) async {
    try {
      final snap = await _venueDoc(uid, venueCode).get();
      final data = snap.data();
      if (data != null) {
        final cloudMs = _updatedAtMs(data);
        final knownMs = prefs.getInt(_lastKnownKey(venueCode)) ?? 0;
        if (shouldPullBeforePush(cloudMs, knownMs)) {
          final suffix = venueKeySuffix(venueCode);
          for (final key in _syncKeys) {
            final value = data[key];
            if (value is String) {
              await prefs.setString('$key$suffix', value);
            }
          }
          await _rememberCloudUpdatedAt(prefs, venueCode, data);
        }
      }
      await pushToCloud(uid, prefs, venueCode);
    } catch (_) {
      // Нет сети — просто пропускаем цикл синхронизации.
    }
  }

  /// Чистая функция решения "нужно ли подтянуть облако перед отправкой
  /// своих данных" — вынесена отдельно от Firestore-вызовов, чтобы её можно
  /// было протестировать без реального/фейкового Firestore.
  static bool shouldPullBeforePush(int? cloudUpdatedAtMs, int lastKnownMs) {
    return cloudUpdatedAtMs != null && cloudUpdatedAtMs > lastKnownMs;
  }

  static int? _updatedAtMs(Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return null;
  }

  static Future<void> _rememberCloudUpdatedAt(
      SharedPreferences prefs, String venueCode, Map<String, dynamic> data) async {
    final ms = _updatedAtMs(data);
    if (ms != null) {
      await prefs.setInt(_lastKnownKey(venueCode), ms);
    }
  }

  /// Безвозвратно удаляет данные заведения из облака (документ
  /// businesses/{uid}/venues/{code}). Реестр заведений (businesses/{uid})
  /// нужно обновить отдельным вызовом pushVenueRegistry после этого.
  static Future<void> deleteVenueCloud(String uid, String venueCode) async {
    try {
      await _venueDoc(uid, venueCode).delete();
    } catch (_) {
      // Нет сети — облачная копия останется, но локально заведение уже
      // удалено; при следующей успешной синхронизации реестра расхождение
      // не страшно, т.к. документ просто больше не упоминается в реестре.
    }
  }

  // ── Только для чтения — используется дашбордом управляющего ────────────
  // Живое чтение "как есть" для агрегации по всем заведениям сразу, без
  // сохранения в локальное хранилище (см. ManagerDashboardScreen).

  static Future<Map<String, dynamic>?> fetchVenueDataRaw(String uid, String venueCode) async {
    try {
      final snap = await _venueDoc(uid, venueCode).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }
}
