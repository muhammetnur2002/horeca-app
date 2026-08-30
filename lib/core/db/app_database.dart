import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/tables.dart';

part 'app_database.g.dart';

/// Локальная база приложения.
///
/// Заменяет SharedPreferences, где все данные лежали одним JSON-блобом
/// на раздел: он целиком перечитывался при старте и целиком перезаписывался
/// при любом изменении, а сбой разбора обнулял весь раздел разом.
///
/// Схема повторяет серверную (см. supabase/migrations), чтобы синхронизация
/// сводилась к переносу строк.
@DriftDatabase(
  tables: [
    EstablishmentSettings,
    Departments,
    Categories,
    Products,
    StaffMembers,
    HistoryEntries,
    ShiftRecords,
    ShiftWriteoffs,
    StockLevels,
    Reminders,
    ExportTemplates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: _databaseName));

  static const _databaseName = 'akyl';

  @override
  int get schemaVersion => 1;

  /// Даты хранятся текстом в формате ISO-8601, а не числом секунд.
  ///
  /// Так сохраняются миллисекунды — они нужны курсорам синхронизации, —
  /// значение остаётся лексикографически сортируемым и читаемым глазами
  /// при разборе проблем.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Внешних ключей в схеме нет намеренно: при синхронизации
          // дочерняя строка может приехать раньше родительской.
          await customStatement('PRAGMA foreign_keys = OFF');
        },
      );
}

/// Единственный экземпляр базы на всё приложение.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
