/// Мгновенная отправка изменений в облако по аккаунту. Раньше данные
/// заведения (товары, категории, история, смены) отправлялись в Firestore
/// только раз в 15 минут таймером и при сворачивании/возврате в приложение
/// (см. HorecaApp._syncIfLoggedIn в app.dart) — то есть заведение хранилось
/// локально, а в облако "долетало" с задержкой. Теперь каждый репозиторий
/// зовёт scheduleSync() сразу после каждого локального сохранения, и
/// изменение уходит в облако почти сразу.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/custom_template/data/template_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/notifications/data/notification_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

class CloudAutoSync {
  final Ref _ref;
  Timer? _debounce;

  // Небольшая задержка, а не мгновенная отправка при каждом вызове — чтобы
  // массовые операции (массовое добавление товаров, смена категории у
  // десятка товаров разом и т.п.) не превращались в десятки отдельных
  // запросов к Firestore подряд. Пользователь всё равно не заметит разницы
  // между "сразу" и "через ~1 секунду".
  static const _debounceDelay = Duration(milliseconds: 800);

  CloudAutoSync(this._ref);

  void scheduleSync() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final venueCode = _ref.read(venueRepositoryProvider).activeVenueCode;
    // Флаг ставим и без аккаунта: правки офлайн не должны потом затереться
    // первым входом в облако.
    CloudSyncService.markLocalPending(prefs, venueCode);
    final account = _ref.read(accountRepositoryProvider);
    if (!account.isLoggedIn || account.uid == null) return;
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _push);
  }

  /// Досылает немедленно, без дебаунса — используется при сворачивании
  /// приложения, чтобы не потерять последнее изменение, если оно попало
  /// точно в окно дебаунса.
  Future<void> flush() async {
    _debounce?.cancel();
    await _push();
  }

  Future<void> _push() async {
    final account = _ref.read(accountRepositoryProvider);
    if (!account.isLoggedIn || account.uid == null) return;
    final prefs = _ref.read(sharedPreferencesProvider);
    final venueCode = _ref.read(venueRepositoryProvider).activeVenueCode;
    final changed =
        await CloudSyncService.syncSmart(account.uid!, prefs, venueCode);
    if (changed) reloadMirrors();
  }

  /// Перечитывает локальные хранилища после того, как синхронизация
  /// записала в SharedPreferences более свежую копию.
  void reloadMirrors() {
    _ref.invalidate(settingsRepositoryProvider);
    _ref.invalidate(historyRepositoryProvider);
    _ref.invalidate(analyticsRepositoryProvider);
    _ref.invalidate(notificationRepositoryProvider);
    _ref.invalidate(stockLevelsRepositoryProvider);
    _ref.invalidate(templateRepositoryProvider);
    _ref.invalidate(supplyRepositoryProvider);
  }

  void dispose() {
    _debounce?.cancel();
  }
}

final cloudAutoSyncProvider = Provider<CloudAutoSync>((ref) {
  final sync = CloudAutoSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});
