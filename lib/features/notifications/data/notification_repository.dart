import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/notifications/data/notification_service.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

enum ReminderFrequency { daily, weekly }

class ProductReminder {
  final int id;
  String productName;
  ReminderFrequency frequency;
  int hour, minute;
  int? weekday; // только для weekly, 1-7

  ProductReminder({
    required this.id,
    required this.productName,
    required this.frequency,
    required this.hour,
    required this.minute,
    this.weekday,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'frequency': frequency.name,
    'hour': hour,
    'minute': minute,
    'weekday': weekday,
  };

  factory ProductReminder.fromJson(Map<String, dynamic> json) => ProductReminder(
    id: json['id'] as int,
    productName: json['productName'] as String,
    frequency: ReminderFrequency.values.firstWhere(
      (e) => e.name == json['frequency'],
      orElse: () => ReminderFrequency.daily,
    ),
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    weekday: json['weekday'] as int?,
  );
}

class InventoryReminder {
  final bool enabled;
  final int dayOfMonth;
  final int hour, minute;
  final bool dayBeforeEnabled;

  const InventoryReminder({
    this.enabled = false,
    this.dayOfMonth = 1,
    this.hour = 9,
    this.minute = 0,
    this.dayBeforeEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'dayOfMonth': dayOfMonth,
    'hour': hour,
    'minute': minute,
    'dayBeforeEnabled': dayBeforeEnabled,
  };

  factory InventoryReminder.fromJson(Map<String, dynamic> json) => InventoryReminder(
    enabled: json['enabled'] as bool? ?? false,
    dayOfMonth: json['dayOfMonth'] as int? ?? 1,
    hour: json['hour'] as int? ?? 9,
    minute: json['minute'] as int? ?? 0,
    dayBeforeEnabled: json['dayBeforeEnabled'] as bool? ?? true,
  );

  InventoryReminder copyWith({
    bool? enabled, int? dayOfMonth, int? hour, int? minute, bool? dayBeforeEnabled,
  }) => InventoryReminder(
    enabled: enabled ?? this.enabled,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    dayBeforeEnabled: dayBeforeEnabled ?? this.dayBeforeEnabled,
  );
}

class NotificationData {
  final List<ProductReminder> productReminders;
  final InventoryReminder inventoryReminder;

  const NotificationData({
    this.productReminders = const [],
    this.inventoryReminder = const InventoryReminder(),
  });

  NotificationData copyWith({
    List<ProductReminder>? productReminders,
    InventoryReminder? inventoryReminder,
  }) => NotificationData(
    productReminders: productReminders ?? this.productReminders,
    inventoryReminder: inventoryReminder ?? this.inventoryReminder,
  );
}

/// Напоминания заведения. Хранятся в базе (таблица reminders), свои
/// у каждого заведения; запланированные уведомления — системные, поэтому
/// напоминания других заведений продолжают срабатывать.
class NotificationRepository extends StateNotifier<NotificationData> {
  final AppDatabase _db;
  final String _venueId;
  final String _venueCode;
  final NotificationService _service = NotificationService();
  String? _inventoryRowId;

  /// Номер уведомления инвентаризации свой у каждого заведения:
  /// у "01" — 999 (как раньше) и 998 для «за день до», у "02" — 997/996…
  /// Напоминания о товарах нумеруются с 1000, пересечений нет.
  int get _invId => 1001 - 2 * (int.tryParse(_venueCode) ?? 1);
  int get _dayBeforeId => _invId - 1;

  NotificationRepository(this._db, this._venueId, this._venueCode)
      : super(const NotificationData()) {
    _load();
    _service.init();
  }

  Future<void> _load() async {
    final rows = await (_db.select(_db.reminders)
          ..where((t) => t.venueId.equals(_venueId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
    if (!mounted) return;
    final products = <ProductReminder>[];
    var inventory = const InventoryReminder();
    for (final r in rows) {
      if (r.frequency == 'monthly') {
        _inventoryRowId = r.id;
        inventory = InventoryReminder(
          enabled: r.isEnabled,
          dayOfMonth: r.dayOfMonth ?? 1,
          hour: r.hour,
          minute: r.minute,
          dayBeforeEnabled: r.remindDayBefore,
        );
      } else if (r.isEnabled) {
        products.add(ProductReminder(
          id: r.notificationId,
          productName: r.title,
          frequency: r.frequency == 'weekly'
              ? ReminderFrequency.weekly
              : ReminderFrequency.daily,
          hour: r.hour,
          minute: r.minute,
          weekday: r.weekday,
        ));
      }
    }
    state = NotificationData(
        productReminders: products, inventoryReminder: inventory);
  }

  /// Следующий свободный номер уведомления — по всем заведениям устройства.
  Future<int> _nextNotificationId() async {
    final max = await (_db.selectOnly(_db.reminders)
          ..addColumns([_db.reminders.notificationId.max()]))
        .map((row) => row.read(_db.reminders.notificationId.max()))
        .getSingleOrNull();
    final next = (max ?? 999) + 1;
    return next < 1000 ? 1000 : next;
  }

  Future<void> addProductReminder({
    required String productName,
    required ReminderFrequency frequency,
    required int hour,
    required int minute,
    int? weekday,
  }) async {
    final id = await _nextNotificationId();
    final reminder = ProductReminder(
      id: id, productName: productName, frequency: frequency,
      hour: hour, minute: minute, weekday: weekday,
    );
    state = state.copyWith(productReminders: [...state.productReminders, reminder]);
    final now = DateTime.now().toUtc();
    await _db.into(_db.reminders).insert(RemindersCompanion.insert(
          id: Ids.newId(),
          createdAt: now,
          updatedAt: now,
          venueId: _venueId,
          notificationId: id,
          title: productName,
          frequency: frequency.name,
          hour: hour,
          minute: minute,
          weekday: Value(frequency == ReminderFrequency.weekly ? weekday : null),
        ));

    final title = 'Заказать товар';
    final body = 'Время заказать: $productName';
    if (frequency == ReminderFrequency.daily) {
      await _service.scheduleDaily(id: id, title: title, body: body, hour: hour, minute: minute);
    } else {
      await _service.scheduleWeekly(id: id, title: title, body: body,
          weekday: weekday ?? 1, hour: hour, minute: minute);
    }
  }

  Future<void> removeProductReminder(int id) async {
    state = state.copyWith(
        productReminders: state.productReminders.where((r) => r.id != id).toList());
    final now = DateTime.now().toUtc();
    await (_db.update(_db.reminders)
          ..where((t) => t.venueId.equals(_venueId) & t.notificationId.equals(id)))
        .write(RemindersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    await _service.cancel(id);
  }

  Future<void> setInventoryReminder(InventoryReminder reminder) async {
    state = state.copyWith(inventoryReminder: reminder);
    final now = DateTime.now().toUtc();
    final rowId = _inventoryRowId ??= Ids.newId();
    final row = RemindersCompanion.insert(
      id: rowId,
      createdAt: now,
      updatedAt: now,
      venueId: _venueId,
      notificationId: _invId,
      title: 'Инвентаризация',
      frequency: 'monthly',
      hour: reminder.hour,
      minute: reminder.minute,
      dayOfMonth: Value(reminder.dayOfMonth),
      remindDayBefore: Value(reminder.dayBeforeEnabled),
      isEnabled: Value(reminder.enabled),
    );
    await _db.into(_db.reminders).insert(row,
        onConflict: DoUpdate((_) => row.copyWith(createdAt: const Value.absent())));

    await _service.cancel(_invId);
    await _service.cancel(_dayBeforeId);

    if (reminder.enabled) {
      await _service.scheduleMonthlyReminder(
        id: _invId,
        title: 'Инвентаризация',
        body: 'Сегодня день инвентаризации',
        dayOfMonth: reminder.dayOfMonth,
        hour: reminder.hour,
        minute: reminder.minute,
      );
      if (reminder.dayBeforeEnabled) {
        final dayBefore = reminder.dayOfMonth == 1 ? 28 : reminder.dayOfMonth - 1;
        await _service.scheduleMonthlyReminder(
          id: _dayBeforeId,
          title: 'Инвентаризация завтра',
          body: 'Не забудьте подготовиться к инвентаризации',
          dayOfMonth: dayBefore,
          hour: reminder.hour,
          minute: reminder.minute,
        );
      }
    }
  }
}

final notificationRepositoryProvider =
    StateNotifierProvider<NotificationRepository, NotificationData>((ref) {
  return NotificationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(activeVenueIdProvider),
    ref.watch(venueRepositoryProvider.select((s) => s.activeVenueCode)),
  );
});
