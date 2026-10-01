import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/custom_template/data/template_models.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:drift/drift.dart';

/// Шаблон колонок PDF инвентаризации. Хранится в базе, свой у каждого
/// заведения (раньше был общим на устройство).
class TemplateRepository extends StateNotifier<CustomTemplate?> {
  final AppDatabase _db;
  final String _venueId;
  String? _rowId;

  TemplateRepository(this._db, this._venueId) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final row = await (_db.select(_db.exportTemplates)
          ..where((t) => t.venueId.equals(_venueId) & t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
    if (!mounted || row == null) return;
    _rowId = row.id;
    try {
      state = CustomTemplate.fromJson(
          jsonDecode(row.templateJson) as Map<String, dynamic>);
    } catch (_) {
      state = null;
    }
  }

  void saveTemplate(CustomTemplate template) {
    state = template;
    final now = DateTime.now().toUtc();
    final id = _rowId ??= Ids.newId();
    final row = ExportTemplatesCompanion.insert(
      id: id,
      createdAt: now,
      updatedAt: now,
      venueId: _venueId,
      name: template.name,
      templateJson: Value(jsonEncode(template.toJson())),
    );
    _db.into(_db.exportTemplates).insert(row,
        onConflict: DoUpdate((_) => row.copyWith(
            createdAt: const Value.absent(), deletedAt: const Value(null))));
  }

  void removeTemplate() {
    state = null;
    final id = _rowId;
    if (id == null) return;
    final now = DateTime.now().toUtc();
    (_db.update(_db.exportTemplates)..where((t) => t.id.equals(id))).write(
        ExportTemplatesCompanion(
            deletedAt: Value(now), updatedAt: Value(now)));
  }
}

final templateRepositoryProvider =
    StateNotifierProvider<TemplateRepository, CustomTemplate?>((ref) {
  return TemplateRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(activeVenueIdProvider),
  );
});
