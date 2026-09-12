import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Нижняя граница диапазона перехода для синтетической зоны.
const int _minTime = -8640000000000000;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  /// Доступны ли локальные уведомления на этой платформе. На вебе, в тестах
  /// и на неподдерживаемых сборках плагина нет — приложение должно работать
  /// без него, а не падать при создании репозитория.
  bool get isAvailable => _plugin != null;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tz_data.initializeTimeZones();
      _setLocalTimeZone();

      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await plugin.initialize(settings: initSettings);
      _plugin = plugin;

      final androidPlugin = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      // Плагин недоступен — напоминания просто не планируются.
      _plugin = null;
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final plugin = _plugin;
    if (plugin == null) return;
    await plugin.zonedSchedule(
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
    final plugin = _plugin;
    if (plugin == null) return;
    await plugin.zonedSchedule(
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
    final plugin = _plugin;
    if (plugin == null) return;
    await plugin.zonedSchedule(
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
    await _plugin?.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin?.cancelAll();
  }

  /// `initializeTimeZones()` только загружает базу — `tz.local` остаётся UTC,
  /// из-за чего все напоминания срабатывали со сдвигом на часовой пояс
  /// устройства. Регистрируем зону с фактическим смещением системы.
  void _setLocalTimeZone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      if (offset == Duration.zero) return; // UTC — уже верно
      final name = now.timeZoneName.isEmpty ? 'Local' : now.timeZoneName;
      final zone = tz.TimeZone(offset, isDst: false, abbreviation: name);
      final location = tz.Location(name, const [_minTime], const [0], [zone]);
      tz.timeZoneDatabase.add(location);
      tz.setLocalLocation(location);
    } catch (_) {
      // Не смогли определить зону — остаёмся на значении по умолчанию.
    }
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

  tz.TZDateTime _nextInstanceOfMonthDay(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (scheduled.isBefore(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      scheduled = tz.TZDateTime(tz.local, nextYear, nextMonth, day, hour, minute);
    }
    return scheduled;
  }
}