import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/tables.dart';

part 'app_database.g.dart';

/// Локальная база приложения.
///
/// Заменяет SharedPreferences, где каждый раздел лежал одним JSON-блобом:
/// он целиком перечитывался и перезаписывался при любом изменении, а в
/// облако уходил одним документом с лимитом 1 МБ.
@DriftDatabase(
  tables: [
    Venues,
    Departments,
    Categories,
    Products,
    StaffMembers,
    HistoryEntries,
    ShiftRecords,
    ShiftWriteoffs,
    StockLevels,
    StockMovements,
    AuditLog,
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

  /// Даты хранятся текстом ISO-8601: сохраняются миллисекунды (нужны
  /// курсорам синхронизации), значение сортируемо и читаемо глазами.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX idx_movements_product ON stock_movements '
              '(venue_id, product_id, occurred_at)');
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
