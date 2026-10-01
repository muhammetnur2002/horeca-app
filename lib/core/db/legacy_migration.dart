import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/core/money.dart';
import 'package:horeca_app/shared/models/department_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Однократный перенос данных из SharedPreferences в базу.
///
/// Основа — перенос из ветки audit-fixes, расширенный на несколько
/// заведений: данные каждого заведения лежат под своим суффиксом ключа
/// ('' у заведения "01", '_02'..'_05' у остальных — см. venueKeySuffix).
///
/// Старые ключи НЕ удаляются: если перенос окажется неполным, исходные
/// данные останутся на месте, и его можно повторить с [force].
///
/// Старые идентификаторы ('1', '2', ... или метки времени) уникальны только
/// внутри одного заведения на одном устройстве, поэтому каждому объекту
/// выдаётся UUID, а ссылки (категория → отдел, товар → категория,
/// остаток → товар) переписываются по карте соответствия.
class LegacyMigration {
  const LegacyMigration._();

  /// Флаг выполнения. Хранится в SharedPreferences, а не в базе:
  /// база может быть пересоздана, а отметка должна пережить это.
  static const doneKey = 'migrated_to_drift_v1';

  static const _venuesKey = 'venues_list';
  static const _settingsKey = 'settings_data';
  static const _historyKey = 'history_data';
  static const _shiftsKey = 'shift_records';
  static const _notificationsKey = 'notification_data';
  static const _templateKey = 'custom_inventory_template';
  static const _stockKey = 'current_stock_levels';

  static bool isDone(SharedPreferences prefs) =>
      prefs.getBool(doneKey) ?? false;

  static String _suffix(String code) => code == '01' ? '' : '_$code';

  /// Переносит данные. Не бросает исключений: любой сбой попадает
  /// в [MigrationReport.failures], а приложение продолжает запускаться.
  ///
  /// Перенос идёт одной транзакцией: при сбое база остаётся пустой,
  /// а старые ключи — нетронутыми (половина перенесённого справочника
  /// выглядела бы для человека как потеря данных).
  static Future<MigrationReport> run({
    required AppDatabase db,
    required SharedPreferences prefs,
    bool force = false,
  }) async {
    final report = MigrationReport();

    if (!force && isDone(prefs)) {
      report.skipped = true;
      return report;
    }

    try {
      await db
          .transaction(() => _migrate(db: db, prefs: prefs, report: report));
    } catch (e) {
      report.failures.add('перенос прерван: $e');
      report.reset();
    }

    // Отметка ставится в любом случае: повтор на тех же испорченных данных
    // упадёт там же. Старые ключи на месте — перенос можно повторить с force.
    await prefs.setBool(doneKey, true);

    debugPrint('Перенос в базу завершён: $report');
    return report;
  }

  static Future<void> _migrate({
    required AppDatabase db,
    required SharedPreferences prefs,
    required MigrationReport report,
  }) async {
    final now = DateTime.now().toUtc();

    // Шаблон PDF и напоминания в старом формате общие на устройство.
    final templateRaw = prefs.getString(_templateKey);

    for (final venue in _readVenues(prefs, report)) {
      final suffix = _suffix(venue.code);
      final settings = _decodeMap(prefs.getString('$_settingsKey$suffix'),
          report, 'настройки ${venue.code}');

      final venueId = Ids.newId();
      final currency = _asString(settings?['currency']) ?? '₸';
      await db.into(db.venues).insert(VenuesCompanion.insert(
            id: venueId,
            createdAt: now,
            updatedAt: now,
            code: venue.code,
            name: venue.name,
            reportName:
                Value(_asString(settings?['establishmentName']) ?? venue.name),
            currency: currency,
            logoPath: Value(_asString(settings?['logoPath'])),
            showShiftDesserts:
                Value(_asBool(settings?['showShiftDesserts']) ?? true),
          ));
      report.venues++;
      report.venueIds[venue.code] = venueId;

      // ── Справочники ──────────────────────────────────────────────────────
      final departmentIds = <String, String>{};
      final categoryIds = <String, String>{};
      final productIds = <String, String>{};
      final productIdByName = <String, String>{};

      var order = 0;
      for (final raw in _asList(settings?['departments'])) {
        final map = _asMap(raw);
        final name = _asString(map?['name']);
        if (map == null || name == null || name.trim().isEmpty) continue;
        final newId = Ids.newId();
        final oldId = _asString(map['id']);
        if (oldId != null) departmentIds[oldId] = newId;
        await db.into(db.departments).insert(DepartmentsCompanion.insert(
              id: newId,
              createdAt: now,
              updatedAt: now,
              venueId: venueId,
              name: name,
              iconKey: Value(DepartmentIcons.keyOfStored(map['icon'])),
              sortOrder: Value(order++),
            ));
        report.departments++;
      }

      order = 0;
      for (final raw in _asList(settings?['categories'])) {
        final map = _asMap(raw);
        final name = _asString(map?['name']);
        if (map == null || name == null || name.trim().isEmpty) continue;
        final newId = Ids.newId();
        final oldId = _asString(map['id']);
        if (oldId != null) categoryIds[oldId] = newId;
        // Как и в SettingsRepository: в старых данных флага нет —
        // один раз угадываем по названию.
        final isDessert = _asBool(map['isDessertCategory']) ??
            name.toLowerCase().contains('десерт');
        await db.into(db.categories).insert(CategoriesCompanion.insert(
              id: newId,
              createdAt: now,
              updatedAt: now,
              venueId: venueId,
              name: name,
              departmentId:
                  Value(departmentIds[_asString(map['departmentId'])]),
              isDessert: Value(isDessert),
              sortOrder: Value(order++),
            ));
        report.categories++;
      }

      order = 0;
      for (final raw in _asList(settings?['products'])) {
        final map = _asMap(raw);
        final name = _asString(map?['name']);
        if (map == null || name == null || name.trim().isEmpty) continue;
        final newId = Ids.newId();
        final oldId = _asString(map['id']);
        if (oldId != null) productIds[oldId] = newId;
        productIdByName.putIfAbsent(name.trim().toLowerCase(), () => newId);
        final unit = _asString(map['unit']) ?? 'шт';
        await db.into(db.products).insert(ProductsCompanion.insert(
              id: newId,
              createdAt: now,
              updatedAt: now,
              venueId: venueId,
              name: name,
              unit: Value(unit),
              inventoryUnit: Value(_asString(map['inventoryUnit']) ?? unit),
              categoryId: Value(categoryIds[_asString(map['categoryId'])]),
              minStock: Value(_asDouble(map['minStock'])),
              sortOrder: Value(order++),
            ));
        report.products++;
      }

      for (final raw in _asList(settings?['staff'])) {
        final name = _asString(raw);
        if (name == null || name.trim().isEmpty) continue;
        // PIN в старом формате общий на роль, а не личный — сотрудники
        // переносятся без PIN, личные коды задаются отдельно.
        await db.into(db.staffMembers).insert(StaffMembersCompanion.insert(
              id: Ids.newId(),
              createdAt: now,
              updatedAt: now,
              venueId: venueId,
              fullName: name.trim(),
            ));
        report.staff++;
      }

      // ── История ──────────────────────────────────────────────────────────
      final history = _decodeList(prefs.getString('$_historyKey$suffix'),
          report, 'история ${venue.code}');
      for (final raw in history) {
        final map = _asMap(raw);
        final title = _asString(map?['title']);
        final body = _asString(map?['text']);
        if (map == null || title == null || body == null) continue;
        await db.into(db.historyEntries).insert(HistoryEntriesCompanion.insert(
              id: Ids.newId(),
              createdAt: _asDate(map['createdAt']) ?? now,
              updatedAt: now,
              venueId: venueId,
              kind: _asString(map['type']) == 'inventory'
                  ? 'inventory'
                  : 'request',
              title: title,
              body: body,
            ));
        report.history++;
      }

      // ── Смены ────────────────────────────────────────────────────────────
      final shifts = _decodeList(
          prefs.getString('$_shiftsKey$suffix'), report, 'смены ${venue.code}');
      for (final raw in shifts) {
        final map = _asMap(raw);
        final closedAt = _asDate(map?['date']);
        if (map == null || closedAt == null) continue;
        final shiftId = Ids.newId();
        await db.into(db.shiftRecords).insert(ShiftRecordsCompanion.insert(
              id: shiftId,
              createdAt: now,
              updatedAt: now,
              venueId: venueId,
              closedAt: closedAt,
              revenueMinor: Value(_toMinor(map['revenue'])),
              qrMinor: Value(_toMinor(map['qr'])),
              cardMinor: Value(_toMinor(map['card'])),
              cashMinor: Value(_toMinor(map['cash'])),
              morningCashMinor: Value(_toMinor(map['morningCash'])),
              eveningCashMinor: Value(_toMinor(map['eveningCash'])),
            ));
        report.shifts++;

        final writeoffs = _asMap(map['writeOffs']);
        if (writeoffs == null) continue;
        for (final entry in writeoffs.entries) {
          final quantity = _asDouble(entry.value);
          if (quantity == null || quantity <= 0 || entry.key.trim().isEmpty) {
            continue;
          }
          await db
              .into(db.shiftWriteoffs)
              .insert(ShiftWriteoffsCompanion.insert(
                id: Ids.newId(),
                shiftId: shiftId,
                // Списания хранились по названию; связываем с товаром,
                // если такой есть в каталоге этого заведения.
                productId:
                    Value(productIdByName[entry.key.trim().toLowerCase()]),
                productName: entry.key,
                quantity: quantity,
                createdAt: closedAt,
              ));
          report.writeoffs++;
        }
      }

      // ── Последние измеренные остатки ─────────────────────────────────────
      // У заведения "01" ключ без суффикса. В старых версиях этот ключ был
      // общим на устройство, а товары разных заведений имели одинаковые id —
      // поэтому остатки без суффикса относим только к "01".
      final stock = _decodeMap(prefs.getString('$_stockKey$suffix'), report,
          'остатки ${venue.code}');
      if (stock != null) {
        for (final entry in stock.entries) {
          final productId = productIds[entry.key];
          final remaining = _asDouble(entry.value);
          if (productId == null || remaining == null) continue;
          await db.into(db.stockLevels).insert(StockLevelsCompanion.insert(
                venueId: venueId,
                productId: productId,
                remaining: remaining,
                measuredAt: now,
                updatedAt: now,
              ));
          report.stockLevels++;
        }
      }

      // ── Напоминания ──────────────────────────────────────────────────────
      // Репозиторий уведомлений хранил их под общим ключом без суффикса,
      // а облачная синхронизация могла положить копию под ключ заведения.
      // Общий ключ относим к "01".
      final notifications = _decodeMap(
          prefs.getString('$_notificationsKey$suffix'),
          report,
          'напоминания ${venue.code}');
      await _migrateReminders(db, notifications, venueId, now, report);

      // ── Шаблон PDF ───────────────────────────────────────────────────────
      // Шаблон был общим на устройство и применялся ко всем заведениям —
      // копируем его в каждое.
      if (templateRaw != null && templateRaw.trim().isNotEmpty) {
        final template = _decodeMap(templateRaw, report, 'шаблон');
        if (template != null) {
          await db
              .into(db.exportTemplates)
              .insert(ExportTemplatesCompanion.insert(
                id: Ids.newId(),
                createdAt: now,
                updatedAt: now,
                venueId: venueId,
                name: _asString(template['name']) ?? 'Шаблон',
                templateJson: Value(templateRaw),
              ));
          report.templates++;
        }
      }
    }
  }

  static Future<void> _migrateReminders(
    AppDatabase db,
    Map<String, dynamic>? notifications,
    String venueId,
    DateTime now,
    MigrationReport report,
  ) async {
    if (notifications == null) return;
    for (final raw in _asList(notifications['productReminders'])) {
      final map = _asMap(raw);
      final title = _asString(map?['productName']);
      final hour = _asInt(map?['hour']);
      final minute = _asInt(map?['minute']);
      final notificationId = _asInt(map?['id']);
      if (map == null ||
          title == null ||
          hour == null ||
          minute == null ||
          notificationId == null) {
        continue;
      }
      final weekly = _asString(map['frequency']) == 'weekly';
      await db.into(db.reminders).insert(RemindersCompanion.insert(
            id: Ids.newId(),
            createdAt: now,
            updatedAt: now,
            venueId: venueId,
            // Тот же номер, под которым напоминание уже запланировано
            // в системе, — чтобы его можно было отменить.
            notificationId: notificationId,
            title: title,
            frequency: weekly ? 'weekly' : 'daily',
            hour: hour,
            minute: minute,
            weekday: Value(weekly ? _asInt(map['weekday']) : null),
          ));
      report.reminders++;
    }

    final inventory = _asMap(notifications['inventoryReminder']);
    if (inventory != null && (_asBool(inventory['enabled']) ?? false)) {
      await db.into(db.reminders).insert(RemindersCompanion.insert(
            id: Ids.newId(),
            createdAt: now,
            updatedAt: now,
            venueId: venueId,
            notificationId: 999,
            title: 'Инвентаризация',
            frequency: 'monthly',
            hour: _asInt(inventory['hour']) ?? 9,
            minute: _asInt(inventory['minute']) ?? 0,
            dayOfMonth: Value(_asInt(inventory['dayOfMonth']) ?? 1),
            remindDayBefore:
                Value(_asBool(inventory['dayBeforeEnabled']) ?? true),
          ));
      report.reminders++;
    }
  }

  /// Заведения из старого списка. Если списка нет или он испорчен —
  /// на устройстве было только заведение "01".
  static List<_LegacyVenue> _readVenues(
      SharedPreferences prefs, MigrationReport report) {
    final list =
        _decodeList(prefs.getString(_venuesKey), report, 'список заведений');
    final venues = <_LegacyVenue>[];
    final seen = <String>{};
    for (final raw in list) {
      final map = _asMap(raw);
      final code = _asString(map?['code']);
      if (code == null || code.length != 2 || !seen.add(code)) continue;
      venues.add(_LegacyVenue(code, _asString(map?['name']) ?? 'Заведение'));
    }
    if (venues.isEmpty) venues.add(const _LegacyVenue('01', 'Моё заведение'));
    return venues;
  }

  // ── Разбор значений старого формата ──────────────────────────────────────
  //
  // Старые данные писались без схемы и версии, поэтому каждое поле
  // проверяется отдельно: неожиданный тип пропускается, а не роняет перенос.

  static Map<String, dynamic>? _decodeMap(
      String? raw, MigrationReport report, String label) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return _asMap(jsonDecode(raw));
    } catch (e) {
      report.failures.add('$label: $e');
      return null;
    }
  }

  static List<dynamic> _decodeList(
      String? raw, MigrationReport report, String label) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } catch (e) {
      report.failures.add('$label: $e');
      return const [];
    }
  }

  static List<dynamic> _asList(Object? value) =>
      value is List ? value : const [];

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map<String, dynamic>
          ? value
          : (value is Map ? value.map((k, v) => MapEntry('$k', v)) : null);

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }

  static DateTime? _asDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    return null;
  }

  /// Дробная сумма → целые минорные единицы. Отрицательные отбрасываются:
  /// минусовой выручки в кассе не бывает.
  static int _toMinor(Object? value) {
    final amount = _asDouble(value) ?? 0;
    if (amount <= 0) return 0;
    return (Money.round(amount) * 100).round();
  }
}

class _LegacyVenue {
  final String code;
  final String name;
  const _LegacyVenue(this.code, this.name);
}

/// Сводка переноса — для отладочного лога и тестов.
class MigrationReport {
  bool skipped = false;

  /// Код заведения → id новой строки в базе.
  final Map<String, String> venueIds = {};

  int venues = 0;
  int departments = 0;
  int categories = 0;
  int products = 0;
  int staff = 0;
  int history = 0;
  int shifts = 0;
  int writeoffs = 0;
  int reminders = 0;
  int templates = 0;
  int stockLevels = 0;

  /// Разделы, которые не удалось разобрать.
  final List<String> failures = [];

  bool get hasFailures => failures.isNotEmpty;

  /// Обнуляет счётчики после отката транзакции: записей в базе нет.
  void reset() {
    venueIds.clear();
    venues = 0;
    departments = 0;
    categories = 0;
    products = 0;
    staff = 0;
    history = 0;
    shifts = 0;
    writeoffs = 0;
    reminders = 0;
    templates = 0;
    stockLevels = 0;
  }

  @override
  String toString() => skipped
      ? 'перенос не требовался'
      : 'заведений $venues, отделов $departments, категорий $categories, '
          'товаров $products, сотрудников $staff, записей истории $history, '
          'смен $shifts (списаний $writeoffs), напоминаний $reminders, '
          'шаблонов $templates, остатков $stockLevels'
          '${failures.isEmpty ? '' : ', сбоев ${failures.length}'}';
}
