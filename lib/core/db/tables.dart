import 'package:drift/drift.dart';

// Таблицы локальной базы.
//
// Основа взята из ветки audit-fixes и дополнена под то, что появилось
// в приложении позже: несколько заведений на устройстве, флаг «десерты»
// у категорий, личные PIN сотрудников, журнал движений товара и журнал
// изменений.
//
// Сквозные правила, общие с будущим сервером:
//
//  * Идентификаторы — UUID, которые генерирует устройство. Записи можно
//    заводить без сети, а отправка на сервер идемпотентна.
//  * Денежные суммы — целые в минорных единицах (копейки, тиыны).
//  * Удаление мягкое, через deletedAt: физическое удаление невозможно
//    синхронизировать — устройство, которое было оффлайн, не узнает
//    об исчезнувшей строке.
//  * Внешних ключей нет: при синхронизации дочерняя строка может приехать
//    раньше родительской, и жёсткая ссылка отвергла бы её.
//
// Классы данных получают суффикс Row через @DataClassName, чтобы
// не конфликтовать с одноимёнными моделями приложения.

/// Общие поля синхронизируемой таблицы.
mixin _Syncable on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Заведение. На устройстве их до пяти, у каждого свой набор данных.
@DataClassName('VenueRow')
class Venues extends Table with _Syncable {
  /// Двузначный код для входа по PIN ('01'..'05').
  TextColumn get code => text().withLength(min: 2, max: 2)();

  /// Название в списке заведений.
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Название, которое печатается в заявках и отчётах.
  TextColumn get reportName =>
      text().withDefault(const Constant('Моё заведение'))();
  TextColumn get currency => text().withLength(min: 1, max: 8)();
  TextColumn get logoPath => text().nullable()();
  BoolColumn get showShiftDesserts =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DepartmentRow')
class Departments extends Table with _Syncable {
  TextColumn get venueId => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Строковый ключ иконки, а не codePoint: динамический IconData
  /// ломает tree-shaking иконок в релизной сборке.
  TextColumn get iconKey => text().withDefault(const Constant('category'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table with _Syncable {
  TextColumn get venueId => text()();
  TextColumn get departmentId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Товары категории показываются в шаге «Смена и списания».
  BoolColumn get isDessert => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table with _Syncable {
  TextColumn get venueId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Единица заявки (например, «коробка»).
  TextColumn get unit => text().withDefault(const Constant('шт'))();

  /// Единица инвентаризации (например, «шт»). В ней же ведётся журнал
  /// движений товара.
  TextColumn get inventoryUnit => text().withDefault(const Constant('шт'))();

  /// Сколько единиц инвентаризации в одной единице заявки
  /// («1 коробка = 12 шт» → 12). Нужно, чтобы поставка, принятая
  /// в коробках, легла в журнал в штуках.
  RealColumn get unitFactor => real().withDefault(const Constant(1))();
  RealColumn get minStock => real().nullable()();

  /// Идентификатор товара в номенклатуре iiko — сопоставление по id,
  /// а не по названию.
  TextColumn get iikoProductId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Сотрудник заведения с личным PIN-кодом.
///
/// Личный PIN нужен, чтобы приложение знало, кто именно принял поставку
/// или провёл инвентаризацию. Хранится только хеш с солью.
@DataClassName('StaffMemberRow')
class StaffMembers extends Table with _Syncable {
  TextColumn get venueId => text()();
  TextColumn get fullName => text().withLength(min: 1, max: 200)();

  /// 'admin' или 'staff'.
  TextColumn get role => text().withDefault(const Constant('staff'))();
  TextColumn get pinHash => text().nullable()();
  TextColumn get pinSalt => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Журнал сформированных заявок и инвентаризаций (готовый текст документа).
@DataClassName('HistoryEntryRow')
class HistoryEntries extends Table with _Syncable {
  TextColumn get venueId => text()();

  /// 'request' или 'inventory'.
  TextColumn get kind => text().withLength(min: 1, max: 32)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get staffId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Закрытые смены. Только добавление: закрытая смена — это факт.
@DataClassName('ShiftRow')
class ShiftRecords extends Table with _Syncable {
  TextColumn get venueId => text()();
  DateTimeColumn get closedAt => dateTime()();

  /// Имена сотрудников на момент закрытия, через перевод строки.
  /// Снимок, а не ссылки: переименование не должно менять закрытую смену.
  TextColumn get staffNames => text().withDefault(const Constant(''))();

  /// Кто закрыл смену (личный PIN).
  TextColumn get closedByStaffId => text().nullable()();

  IntColumn get revenueMinor => integer().withDefault(const Constant(0))();
  IntColumn get qrMinor => integer().withDefault(const Constant(0))();
  IntColumn get cardMinor => integer().withDefault(const Constant(0))();
  IntColumn get cashMinor => integer().withDefault(const Constant(0))();
  IntColumn get morningCashMinor => integer().withDefault(const Constant(0))();
  IntColumn get eveningCashMinor => integer().withDefault(const Constant(0))();
  IntColumn get inkassMinor => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShiftWriteoffRow')
class ShiftWriteoffs extends Table {
  TextColumn get id => text()();
  TextColumn get shiftId => text()();

  /// Ссылка на товар каталога, если списание сделано по товару
  /// (десерты); у ручных списаний её нет.
  TextColumn get productId => text().nullable()();

  /// Название на момент списания.
  TextColumn get productName => text().withLength(min: 1, max: 200)();
  RealColumn get quantity => real()();
  TextColumn get unit => text().withDefault(const Constant('шт'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Последний измеренный остаток по товару (баннер «заканчивается»).
@DataClassName('StockLevelRow')
class StockLevels extends Table {
  TextColumn get venueId => text()();
  TextColumn get productId => text()();
  RealColumn get remaining => real()();
  DateTimeColumn get measuredAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {venueId, productId};
}

/// Журнал движений товара — основа товарного учёта.
///
/// Только добавление: строки не редактируются и не удаляются. Ошибку
/// исправляют новой строкой вида 'adjustment' с причиной — так видна вся
/// история «откуда взялась цифра». Количество — в единице инвентаризации
/// товара, со знаком: приход положительный, расход отрицательный.
@DataClassName('StockMovementRow')
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get venueId => text()();
  TextColumn get productId => text()();

  /// 'baseline' — стартовая инвентаризация (точка отсчёта),
  /// 'receipt' — приход по накладной,
  /// 'sale' — расход по продажам,
  /// 'writeoff' — списание,
  /// 'count' — результат инвентаризации,
  /// 'adjustment' — ручная корректировка.
  TextColumn get kind => text().withLength(min: 1, max: 16)();
  RealColumn get quantity => real()();
  DateTimeColumn get occurredAt => dateTime()();

  /// Документ-источник: накладная, смена, инвентаризация.
  TextColumn get sourceType => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get staffId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Журнал изменений: кто, когда и что поменял.
///
/// Только добавление. Нужен для защиты от обмана: исправление принятой
/// поставки или инвентаризации остаётся видно вместе с тем, что было до.
@DataClassName('AuditLogRow')
class AuditLog extends Table {
  TextColumn get id => text()();
  TextColumn get venueId => text()();
  DateTimeColumn get at => dateTime()();
  TextColumn get staffId => text().nullable()();

  /// Тип объекта ('product', 'receipt', ...) и его id.
  TextColumn get entity => text().withLength(min: 1, max: 32)();
  TextColumn get entityId => text()();

  /// 'create', 'update', 'delete'.
  TextColumn get action => text().withLength(min: 1, max: 16)();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text().nullable()();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReminderRow')
class Reminders extends Table with _Syncable {
  TextColumn get venueId => text()();

  /// Числовой идентификатор для flutter_local_notifications.
  IntColumn get notificationId => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// 'daily', 'weekly' или 'monthly'.
  TextColumn get frequency => text().withLength(min: 1, max: 16)();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();

  /// 1–7, только для еженедельных.
  IntColumn get weekday => integer().nullable()();

  /// 1–31, только для ежемесячных.
  IntColumn get dayOfMonth => integer().nullable()();

  /// Для ежемесячного напоминания об инвентаризации — ещё и за день до.
  BoolColumn get remindDayBefore =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Шаблон колонок PDF инвентаризации.
@DataClassName('ExportTemplateRow')
class ExportTemplates extends Table with _Syncable {
  TextColumn get venueId => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Шаблон в том же JSON-формате, что и CustomTemplate.toJson().
  TextColumn get templateJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
