import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _plugin.initialize(settings: initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
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
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
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

  // Кол-во дней в месяце — нужно, чтобы день вроде 31 не "переехал"
  // молча в начало следующего месяца в феврале/апреле и т.п.
  // (DateTime(year, month, 31) в Dart не бросает ошибку, а просто
  // прибавляет лишние дни к следующему месяцу).
  int _daysInMonth(int year, int month) {
    final firstOfNextMonth =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  tz.TZDateTime _nextInstanceOfMonthDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final clampedDay =
        day.clamp(1, _daysInMonth(now.year, now.month));
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, clampedDay, hour, minute);
    if (scheduled.isBefore(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final clampedNextDay = day.clamp(1, _daysInMonth(nextYear, nextMonth));
      scheduled = tz.TZDateTime(
          tz.local, nextYear, nextMonth, clampedNextDay, hour, minute);
    }
    return scheduled;
  }
}
