import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/core/money.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Однократный перенос данных из SharedPreferences в базу.
///
/// Запускается при первом старте версии с базой и больше не повторяется:
/// факт выполнения отмечается флагом. Старые ключи НЕ удаляются — если
/// перенос окажется неполным, исходные данные останутся на месте и их
/// можно будет разобрать вручную.
///
/// Основная сложность — идентификаторы. В старом формате это были
/// последовательные строки '1', '2', '3', уникальные только внутри одного
/// устройства. Синхронизация с ними невозможна: два телефона гарантированно
/// дадут одинаковые id разным товарам. Поэтому каждому объекту выдаётся
/// UUID, а ссылки между ними (категория → отдел, товар → категория,
/// остаток → товар) переписываются по карте соответствия.
class LegacyMigration {
  const LegacyMigration._();

  /// Флаг выполнения. Хранится в SharedPreferences, а не в базе:
  /// база может быть пересоздана, а отметка должна пережить это.
  static const _doneKey = 'migrated_to_drift_v1';

  // Ключи старого формата.
  static const _settingsKey = 'settings_data';
  static const _historyKey = 'history_data';
  static const _shiftsKey = 'shift_records';
  static const _notificationsKey = 'notification_data';
  static const _templateKey = 'custom_inventory_template';
  static const _stockKey = 'current_stock_levels';

  static bool isDone(SharedPreferences prefs) =>
      prefs.getBool(_doneKey) ?? false;

  /// Переносит данные. Возвращает сводку — сколько чего перенесено.
  ///
  /// Метод не бросает исключений. Любой сбой — повреждённый JSON, значение
  /// неожиданного типа, нарушенное ограничение таблицы — попадает
  /// в [MigrationReport.failures]. Приложение должно запускаться даже
  /// с испорченными старыми данными: показать пустой справочник неприятно,
  /// уронить запуск — хуже.
  ///
  /// Гранулярность отката — вся запись целиком: перенос идёт одной
  /// транзакцией, поэтому сбой на любом шаге отменяет её. Это осознанный
  /// выбор: половина перенесённого справочника выглядела бы для человека
  /// как потеря данных, а так он видит пустую базу и нетронутые старые
  /// ключи, из которых перенос можно повторить с [force].
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
      await _migrate(db: db, prefs: prefs, report: report);
    } catch (e) {
      report.failures.add('перенос прерван: $e');
      report.reset();
    }

    // Отметка ставится в любом случае. Повтор при испорченных данных
    // не поможет — он упадёт там же, зато успевшие пройти разделы
    // задвоятся. Старые ключи остаются на месте: перенос можно
    // повторить вручную через force после починки данных.
    await prefs.setBool(_doneKey, true);

    debugPrint('Перенос в базу завершён: $report');
    return report;
  }

  static Future<void> _migrate({
    required AppDatabase db,
    required SharedPreferences prefs,
    required MigrationReport report,
  }) async {

    final now = DateTime.now().toUtc();
    final establishmentId = Ids.newId();

    // Карты соответствия старых идентификаторов новым.
    final departmentIds = <String, String>{};
    final categoryIds = <String, String>{};
    final productIds = <String, String>{};

    final settings = _decodeMap(prefs.getString(_settingsKey), report, 'настройки');

    await db.transaction(() async {
      // ── Заведение ──────────────────────────────────────────────────────────
      await db.into(db.establishmentSettings).insert(
            EstablishmentSettingsCompanion.insert(
              id: establishmentId,
              createdAt: now,
              updatedAt: now,
              currency: _asString(settings?['currency']) ?? '₸',
              name: Value(_asString(settings?['establishmentName']) ??
                  'Моё заведение'),
              logoPath: Value(_asString(settings?['logoPath'])),
            ),
          );

      // ── Отделы ─────────────────────────────────────────────────────────────
      for (final raw in _asList(settings?['departments'])) {
        final map = _asMap(raw);
        if (map == null) continue;
        final oldId = _asString(map['id']);
        final name = _asString(map['name']);
        if (name == null || name.trim().isEmpty) continue;

        final newId = Ids.newId();
        if (oldId != null) departmentIds[oldId] = newId;

        await db.into(db.departments).insert(
              DepartmentsCompanion.insert(
                id: newId,
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                name: name,
                iconKey: Value(_asIconKey(map['icon'])),
                sortOrder: Value(report.departments),
              ),
            );
        report.departments++;
      }

      // ── Категории ──────────────────────────────────────────────────────────
      for (final raw in _asList(settings?['categories'])) {
        final map = _asMap(raw);
        if (map == null) continue;
        final oldId = _asString(map['id']);
        final name = _asString(map['name']);
        if (name == null || name.trim().isEmpty) continue;

        final newId = Ids.newId();
        if (oldId != null) categoryIds[oldId] = newId;

        await db.into(db.categories).insert(
              CategoriesCompanion.insert(
                id: newId,
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                name: name,
                departmentId:
                    Value(departmentIds[_asString(map['departmentId'])]),
                sortOrder: Value(report.categories),
              ),
            );
        report.categories++;
      }

      // ── Товары ─────────────────────────────────────────────────────────────
      for (final raw in _asList(settings?['products'])) {
        final map = _asMap(raw);
        if (map == null) continue;
        final oldId = _asString(map['id']);
        final name = _asString(map['name']);
        if (name == null || name.trim().isEmpty) continue;

        final newId = Ids.newId();
        if (oldId != null) productIds[oldId] = newId;

        final unit = _asString(map['unit']) ?? 'шт';
        await db.into(db.products).insert(
              ProductsCompanion.insert(
                id: newId,
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                name: name,
                unit: Value(unit),
                inventoryUnit: Value(_asString(map['inventoryUnit']) ?? unit),
                categoryId: Value(categoryIds[_asString(map['categoryId'])]),
                minStock: Value(_asDouble(map['minStock'])),
                sortOrder: Value(report.products),
              ),
            );
        report.products++;
      }

      // ── Сотрудники ─────────────────────────────────────────────────────────
      for (final raw in _asList(settings?['staff'])) {
        final name = _asString(raw);
        if (name == null || name.trim().isEmpty) continue;
        await db.into(db.staffMembers).insert(
              StaffMembersCompanion.insert(
                id: Ids.newId(),
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                fullName: name,
              ),
            );
        report.staff++;
      }

      // ── Журнал ─────────────────────────────────────────────────────────────
      final history = _decodeList(prefs.getString(_historyKey), report, 'история');
      for (final raw in history) {
        final map = _asMap(raw);
        if (map == null) continue;
        final title = _asString(map['title']);
        final body = _asString(map['text']);
        if (title == null || body == null) continue;

        await db.into(db.historyEntries).insert(
              HistoryEntriesCompanion.insert(
                id: Ids.newId(),
                createdAt: _asDate(map['createdAt']) ?? now,
                updatedAt: now,
                establishmentId: establishmentId,
                kind: _asString(map['type']) == 'inventory'
                    ? 'inventory'
                    : 'request',
                title: title,
                body: body,
              ),
            );
        report.history++;
      }

      // ── Смены ──────────────────────────────────────────────────────────────
      final shifts = _decodeList(prefs.getString(_shiftsKey), report, 'смены');
      for (final raw in shifts) {
        final map = _asMap(raw);
        if (map == null) continue;
        final closedAt = _asDate(map['date']);
        if (closedAt == null) continue;

        final shiftId = Ids.newId();
        await db.into(db.shiftRecords).insert(
              ShiftRecordsCompanion.insert(
                id: shiftId,
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                closedAt: closedAt,
                // Суммы хранились дробными. Переводим в минорные единицы:
                // на клиенте и на сервере деньги теперь только целые.
                revenueMinor: Value(_toMinor(map['revenue'])),
                qrMinor: Value(_toMinor(map['qr'])),
                cardMinor: Value(_toMinor(map['card'])),
                cashMinor: Value(_toMinor(map['cash'])),
                morningCashMinor: Value(_toMinor(map['morningCash'])),
                eveningCashMinor: Value(_toMinor(map['eveningCash'])),
              ),
            );
        report.shifts++;

        final writeoffs = _asMap(map['writeOffs']);
        if (writeoffs == null) continue;
        for (final entry in writeoffs.entries) {
          final quantity = _asDouble(entry.value);
          if (quantity == null || quantity <= 0) continue;
          await db.into(db.shiftWriteoffs).insert(
                ShiftWriteoffsCompanion.insert(
                  id: Ids.newId(),
                  shiftId: shiftId,
                  productName: entry.key,
                  quantity: quantity,
                  createdAt: closedAt,
                ),
              );
          report.writeoffs++;
        }
      }

      // ── Напоминания ────────────────────────────────────────────────────────
      final notifications =
          _decodeMap(prefs.getString(_notificationsKey), report, 'напоминания');
      var notificationId = 1000;
      for (final raw in _asList(notifications?['productReminders'])) {
        final map = _asMap(raw);
        if (map == null) continue;
        final title = _asString(map['productName']);
        final hour = _asInt(map['hour']);
        final minute = _asInt(map['minute']);
        if (title == null || hour == null || minute == null) continue;

        final frequency = _asString(map['frequency']) == 'weekly'
            ? 'weekly'
            : 'daily';
        await db.into(db.reminders).insert(
              RemindersCompanion.insert(
                id: Ids.newId(),
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                notificationId: _asInt(map['id']) ?? notificationId++,
                title: title,
                frequency: frequency,
                hour: hour,
                minute: minute,
                weekday: Value(
                    frequency == 'weekly' ? _asInt(map['weekday']) : null),
              ),
            );
        report.reminders++;
      }

      final inventoryReminder = _asMap(notifications?['inventoryReminder']);
      if (inventoryReminder != null &&
          (_asBool(inventoryReminder['enabled']) ?? false)) {
        await db.into(db.reminders).insert(
              RemindersCompanion.insert(
                id: Ids.newId(),
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                notificationId: 999,
                title: 'Инвентаризация',
                frequency: 'monthly',
                hour: _asInt(inventoryReminder['hour']) ?? 9,
                minute: _asInt(inventoryReminder['minute']) ?? 0,
                dayOfMonth: Value(_asInt(inventoryReminder['dayOfMonth']) ?? 1),
              ),
            );
        report.reminders++;
      }

      // ── Шаблон выгрузки ────────────────────────────────────────────────────
      final templateRaw = prefs.getString(_templateKey);
      if (templateRaw != null && templateRaw.trim().isNotEmpty) {
        await db.into(db.exportTemplates).insert(
              ExportTemplatesCompanion.insert(
                id: Ids.newId(),
                createdAt: now,
                updatedAt: now,
                establishmentId: establishmentId,
                name: 'Перенесённый шаблон',
                // Разбор структуры остаётся на клиенте: здесь сохраняем
                // содержимое как есть, чтобы ничего не потерять.
                columnsJson: Value(templateRaw),
              ),
            );
        report.templates++;
      }

      // ── Остатки ────────────────────────────────────────────────────────────
      final stock = _decodeMap(prefs.getString(_stockKey), report, 'остатки');
      if (stock != null) {
        for (final entry in stock.entries) {
          final newProductId = productIds[entry.key];
          final remaining = _asDouble(entry.value);
          if (newProductId == null || remaining == null) continue;
          await db.into(db.stockLevels).insert(
                StockLevelsCompanion.insert(
                  establishmentId: establishmentId,
                  productId: newProductId,
                  remaining: remaining,
                  measuredAt: now,
                  updatedAt: now,
                ),
              );
          report.stockLevels++;
        }
      }
    });

    report.establishmentId = establishmentId;
  }

  // ── Разбор значений старого формата ──────────────────────────────────────
  //
  // Старые данные писались без схемы и без версии, поэтому каждое поле
  // проверяется отдельно. Неожиданный тип пропускается, а не роняет перенос.

  static Map<String, dynamic>? _decodeMap(
      String? raw, MigrationReport report, String label) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
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

  /// Ключ иконки отдела.
  ///
  /// В старом формате в этом поле встречались и строковый ключ, и числовой
  /// codePoint — иконки когда-то хранились как `IconData.codePoint`.
  /// Число ключом быть не может: карта иконок ищет по строке и вернёт
  /// пустоту, а отдел останется без значка. Поэтому всё, что не похоже
  /// на ключ, заменяется значением по умолчанию.
  static String _asIconKey(Object? value) {
    const fallback = 'category';
    final text = _asString(value);
    if (text == null) return fallback;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return fallback;
    if (RegExp(r'^[0-9]+$').hasMatch(trimmed)) return fallback;
    return trimmed;
  }

  /// Дробная сумма в целые минорные единицы.
  ///
  /// Отрицательные суммы отбрасываются: таблица смен их не принимает
  /// (в кассе не бывает минусовой выручки), и одна испорченная запись
  /// иначе отменила бы весь перенос.
  static int _toMinor(Object? value) {
    final amount = _asDouble(value) ?? 0;
    if (amount <= 0) return 0;
    return (Money.round(amount) * 100).round();
  }
}

/// Сводка переноса. Показывается в отладочном логе и используется тестами.
class MigrationReport {
  bool skipped = false;
  String? establishmentId;

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

  /// Разделы, которые не удалось разобрать. Перенос при этом не прерывается:
  /// лучше перенести часть, чем ничего.
  final List<String> failures = [];

  bool get hasFailures => failures.isNotEmpty;

  /// Обнуляет счётчики после отката транзакции: записей в базе нет,
  /// и сводка не должна утверждать обратное.
  void reset() {
    establishmentId = null;
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
      : 'отделов $departments, категорий $categories, товаров $products, '
          'сотрудников $staff, записей истории $history, смен $shifts '
          '(списаний $writeoffs), напоминаний $reminders, '
          'шаблонов $templates, остатков $stockLevels'
          '${failures.isEmpty ? '' : ', сбоев ${failures.length}'}';
}
