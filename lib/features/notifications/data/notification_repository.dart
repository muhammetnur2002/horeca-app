import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';
import 'package:horeca_app/features/notifications/data/notification_service.dart';

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

class NotificationRepository extends StateNotifier<NotificationData> {
  final SharedPreferences _prefs;
  final NotificationService _service = NotificationService();
  final void Function()? _onChanged;
  static const _key = 'notification_data';
  int _nextId = 1000;

  NotificationRepository(this._prefs, {void Function()? onChanged})
      : _onChanged = onChanged,
        super(const NotificationData()) {
    _load();
    _service.init();
  }

  void _load() {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return;
    try {
      final data = jsonDecode(jsonString);
      final reminders = (data['productReminders'] as List)
          .map((e) => ProductReminder.fromJson(e)).toList();
      final invReminder = InventoryReminder.fromJson(data['inventoryReminder'] ?? {});
      state = NotificationData(productReminders: reminders, inventoryReminder: invReminder);
      if (reminders.isNotEmpty) {
        _nextId = reminders.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      }
    } catch (_) {}
  }

  void _save() {
    final data = {
      'productReminders': state.productReminders.map((r) => r.toJson()).toList(),
      'inventoryReminder': state.inventoryReminder.toJson(),
    };
    _prefs.setString(_key, jsonEncode(data));
    _onChanged?.call();
  }

  Future<void> addProductReminder({
    required String productName,
    required ReminderFrequency frequency,
    required int hour,
    required int minute,
    int? weekday,
  }) async {
    final id = _nextId++;
    final reminder = ProductReminder(
      id: id, productName: productName, frequency: frequency,
      hour: hour, minute: minute, weekday: weekday,
    );
    state = state.copyWith(productReminders: [...state.productReminders, reminder]);
    _save();

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
    _save();
    await _service.cancel(id);
  }

  Future<void> setInventoryReminder(InventoryReminder reminder) async {
    state = state.copyWith(inventoryReminder: reminder);
    _save();

    const invId = 999;
    const dayBeforeId = 998;
    await _service.cancel(invId);
    await _service.cancel(dayBeforeId);

    if (reminder.enabled) {
      await _service.scheduleMonthlyReminder(
        id: invId,
        title: 'Инвентаризация',
        body: 'Сегодня день инвентаризации',
        dayOfMonth: reminder.dayOfMonth,
        hour: reminder.hour,
        minute: reminder.minute,
      );
      if (reminder.dayBeforeEnabled) {
        final dayBefore = reminder.dayOfMonth == 1 ? 28 : reminder.dayOfMonth - 1;
        await _service.scheduleMonthlyReminder(
          id: dayBeforeId,
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
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationRepository(prefs,
      onChanged: () => ref.read(cloudAutoSyncProvider).scheduleSync());
});
