import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';

// Тестируем только чистую логику принятия решения "подтянуть облако перед
// отправкой своих данных" (CloudSyncService.shouldPullBeforePush) — без
// реального Firestore, поэтому тест лёгкий и не требует эмулятора/сети.
void main() {
  group('CloudSyncService.shouldPullBeforePush', () {
    test('облако новее, чем последняя известная версия — нужно подтянуть', () {
      expect(CloudSyncService.shouldPullBeforePush(2000, 1000), isTrue);
    });

    test('облако совпадает с последней известной версией — не нужно', () {
      expect(CloudSyncService.shouldPullBeforePush(1000, 1000), isFalse);
    });

    test('облако старее (не должно случаться, но на всякий случай) — не нужно', () {
      expect(CloudSyncService.shouldPullBeforePush(500, 1000), isFalse);
    });

    test('в облаке ещё ничего нет (null) — не нужно', () {
      expect(CloudSyncService.shouldPullBeforePush(null, 0), isFalse);
    });

    test('первая синхронизация устройства (knownMs = 0), в облаке уже есть данные', () {
      expect(CloudSyncService.shouldPullBeforePush(123456, 0), isTrue);
    });
  });
}
