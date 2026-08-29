import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _darwinDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Раньше настроек для iOS не было вовсе — на iPhone уведомления
    // не инициализировались и не работали.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Без этого tz.local остаётся UTC: initializeTimeZones() только загружает
  /// базу зон, но не выбирает локальную. Из-за этого все напоминания
  /// срабатывали со сдвигом на часовой пояс устройства.
  Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: не удалось определить часовой пояс: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'akyl_daily',
          'Ежедневные напоминания',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday, // 1 = Monday ... 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfWeekday(weekday, hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'akyl_weekly',
          'Еженедельные напоминания',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleMonthlyReminder({
    required int id,
    required String title,
    required String body,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfMonthDay(dayOfMonth, hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'akyl_monthly',
          'Ежемесячные напоминания',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: _darwinDetails,
        macOS: _darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfMonthDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = _clampedMonthDay(now.year, now.month, day, hour, minute);
    if (scheduled.isBefore(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      scheduled = _clampedMonthDay(nextYear, nextMonth, day, hour, minute);
    }
    return scheduled;
  }

  /// 31-е число в 30-дневном месяце раньше перескакивало на 1-е следующего.
  /// Прижимаем к последнему дню месяца.
  tz.TZDateTime _clampedMonthDay(
      int year, int month, int day, int hour, int minute) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return tz.TZDateTime(tz.local, year, month, safeDay, hour, minute);
  }
}
