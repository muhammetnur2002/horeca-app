import 'package:drift/drift.dart';

// Таблицы локальной базы.
//
// Схема повторяет серверную (supabase/migrations), чтобы синхронизация
// на третьем этапе сводилась к переносу строк, а не к преобразованию моделей.
//
// Три сквозных правила, общих с сервером:
//
//  * Идентификаторы — UUID, которые генерирует устройство. Это позволяет
//    заводить записи без сети и делает отправку идемпотентной.
//  * Денежные суммы — целые в минорных единицах (тиыны). Ни double,
//    ни строки: одна единица измерения на клиент и сервер.
//  * Удаление мягкое, через deletedAt. Физическое удаление невозможно
//    синхронизировать: устройство, которое было оффлайн, не узнает
//    об исчезнувшей строке.
//
// Классы данных получают суффикс Row через @DataClassName. Без него drift
// назвал бы их HistoryEntry и ShiftRecord — а такие классы уже есть
// в приложении, и репозиторий, импортирующий оба, не собрался бы.
//
// Внешних ключей намеренно нет. При синхронизации порядок прихода строк
// не гарантирован, и дочерняя запись вполне может приехать раньше
// родительской — жёсткая ссылка отвергла бы её.

/// Общие поля синхронизируемой таблицы.
mixin _Syncable on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Настройки заведения. Строка ровно одна.
@DataClassName('EstablishmentRow')
class EstablishmentSettings extends Table with _Syncable {
  TextColumn get name => text().withDefault(const Constant('Моё заведение'))();
  TextColumn get currency => text().withLength(min: 1, max: 8)();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Ashgabat'))();
  TextColumn get logoPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DepartmentRow')
class Departments extends Table with _Syncable {
  TextColumn get establishmentId => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Строковый ключ иконки, а не числовой codePoint: динамический IconData
  /// ломает tree-shaking иконок в релизной сборке.
  TextColumn get iconKey => text().withDefault(const Constant('category'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table with _Syncable {
  TextColumn get establishmentId => text()();
  TextColumn get departmentId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table with _Syncable {
  TextColumn get establishmentId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get unit => text().withDefault(const Constant('шт'))();

  /// Единица инвентаризации может отличаться от единицы заказа:
  /// заказывают упаковками, считают штуками.
  TextColumn get inventoryUnit => text().withDefault(const Constant('шт'))();
  RealColumn get minStock => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Справочник имён для отметки «кто работал в смену».
/// Это не учётные записи — те появятся на четвёртом этапе.
@DataClassName('StaffMemberRow')
class StaffMembers extends Table with _Syncable {
  TextColumn get establishmentId => text()();
  TextColumn get fullName => text().withLength(min: 1, max: 200)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Журнал сформированных заявок и инвентаризаций.
///
/// Хранит готовый текст документа — так это работает в приложении сегодня.
/// Разбор на позиции появится вместе с синхронизацией.
@DataClassName('HistoryEntryRow')
class HistoryEntries extends Table with _Syncable {
  TextColumn get establishmentId => text()();

  /// 'request' или 'inventory'.
  TextColumn get kind => text().withLength(min: 1, max: 32)();
  TextColumn get title => text()();
  TextColumn get body => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Закрытые смены. Правило синхронизации — только добавление:
/// закрытая смена это факт, а не изменяемая строка.
@DataClassName('ShiftRow')
class ShiftRecords extends Table with _Syncable {
  TextColumn get establishmentId => text()();
  DateTimeColumn get closedAt => dateTime()();

  /// Имена сотрудников на момент закрытия, через перевод строки.
  /// Снимок, а не ссылки: переименование сотрудника не должно менять
  /// уже закрытую смену.
  TextColumn get staffNames => text().withDefault(const Constant(''))();

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

  /// Название на момент списания, а не ссылка на товар.
  TextColumn get productName => text().withLength(min: 1, max: 200)();
  RealColumn get quantity => real()();
  TextColumn get unit => text().withDefault(const Constant('шт'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Последний известный остаток по товару.
@DataClassName('StockLevelRow')
class StockLevels extends Table {
  TextColumn get establishmentId => text()();
  TextColumn get productId => text()();
  RealColumn get remaining => real()();
  DateTimeColumn get measuredAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {establishmentId, productId};
}

@DataClassName('ReminderRow')
class Reminders extends Table with _Syncable {
  TextColumn get establishmentId => text()();

  /// Числовой идентификатор для flutter_local_notifications:
  /// плагин адресует уведомления int, а не строкой.
  IntColumn get notificationId => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// 'daily', 'weekly' или 'monthly'.
  TextColumn get frequency => text().withLength(min: 1, max: 16)();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();

  /// 1–7, только для еженедельных.
  IntColumn get weekday => integer().nullable()();

  /// 1–31, только для ежемесячных. День 29–31 в коротком месяце
  /// прижимается к последнему дню — эта логика остаётся на клиенте.
  IntColumn get dayOfMonth => integer().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Шаблоны выгрузки инвентаризации в Excel.
@DataClassName('ExportTemplateRow')
class ExportTemplates extends Table with _Syncable {
  TextColumn get establishmentId => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Соответствие колонок полям, в формате JSON:
  /// [{"header": "...", "field": "..."}]
  TextColumn get columnsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
