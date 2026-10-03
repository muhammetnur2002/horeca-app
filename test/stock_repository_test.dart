import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/dao/operations_dao.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/history/domain/history_entry.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/domain/receipt_report.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late OperationsDao ops;
  late String venueId;
  late StockRepository stock;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ops = OperationsDao(db);
    venueId = await CatalogDao(db).upsertVenue(code: '01', name: 'Центр');
    stock = StockRepository(ops, venueId);
  });
  tearDown(() => db.close());

  test('заявка → приёмка: приход в единицах инвентаризации и сверка', () async {
    final history = HistoryRepository(ops, venueId);
    await history.ready;
    await history.add(
      HistoryEntry(
        id: 'req-1',
        type: HistoryType.request,
        title: 'Заявка: Кухня',
        text: 'текст',
        createdAt: DateTime(2026, 10, 1),
      ),
      lines: const [
        DocumentLineInput(
            productId: 'milk', productName: 'Молоко', unit: 'коробка',
            ordered: 2, quantity: 2),
        DocumentLineInput(
            productId: 'eggs', productName: 'Яйца', unit: 'шт',
            ordered: 30, quantity: 30),
      ],
    );
    // Заявка сохраняется с тем же id, что и в памяти.
    final requests = await stock.documents('request');
    expect(requests.single.id, 'req-1');
    final reqLines = await stock.lines('req-1');
    expect(reqLines.map((l) => l.ordered), [2, 30]);

    await stock.recordCount({'milk': 3}, baseline: true,
        at: DateTime(2026, 10, 1, 8));
    final receiptId = await stock.recordReceipt(
      requestId: 'req-1',
      title: 'Приёмка: Заявка: Кухня',
      text: 'отчёт',
      at: DateTime(2026, 10, 2, 10),
      lines: const [
        ReceiptLine(productId: 'milk', productName: 'Молоко',
            unit: 'коробка', unitFactor: 12, ordered: 2, received: 1),
        ReceiptLine(productId: 'eggs', productName: 'Яйца', unit: 'шт',
            ordered: 30, received: 0),
      ],
      actor: const Actor(staffId: 's1', name: 'Айгуль'),
    );

    final receipt = (await stock.documents('receipt')).single;
    expect(receipt.id, receiptId);
    expect(receipt.refId, 'req-1');
    expect(receipt.staffId, 's1');
    // Приёмка не попадает в экран истории заявок/инвентаризаций.
    final reloaded = HistoryRepository(ops, venueId);
    await reloaded.ready;
    expect(reloaded.getAll().map((e) => e.id), ['req-1']);

    final ledger = await stock.ledger(
        from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 3));
    expect(ledger['milk']!.received, 12); // 1 коробка × 12
    expect(ledger['milk']!.end, 15);
    expect(ledger.containsKey('eggs'), isFalse); // ничего не пришло

    final audit = await stock.audit();
    expect(audit.map((a) => a.entity), containsAll(['receipt', 'baseline']));
  });

  test('повторная запись списаний одной смены не задваивает учёт', () async {
    await stock.recordCount({'cake': 10}, at: DateTime(2026, 10, 1));
    for (var i = 0; i < 2; i++) {
      await stock.recordWriteoffs({'cake': 2},
          shiftId: 'shift-1', at: DateTime(2026, 10, 2));
    }
    final l = (await stock.ledger(
        from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 3)))['cake']!;
    expect(l.writtenOff, 2);
    expect(l.end, 8);
  });

  test('отчёт о приёмке разделяет пришло / не всё / не пришло / сверх', () {
    final text = buildReceiptReport(
      venueName: 'Центр',
      at: DateTime(2026, 10, 2, 9, 5),
      staffName: 'Айгуль',
      requestTitle: 'Заявка: Кухня',
      lines: const [
        ReceiptLine(productId: 'a', productName: 'Молоко', unit: 'л',
            ordered: 10, received: 10),
        ReceiptLine(productId: 'b', productName: 'Сыр', unit: 'кг',
            ordered: 5, received: 3.5),
        ReceiptLine(productId: 'c', productName: 'Яйца', unit: 'шт',
            ordered: 30, received: 0),
        ReceiptLine(productId: 'd', productName: 'Лимон', unit: 'кг',
            received: 1),
      ],
    );
    expect(text, contains('02.10.2026 09:05'));
    expect(text, contains('Принял(а): Айгуль'));
    expect(text, contains('Молоко — 10 л'));
    expect(text, contains('Сыр — 3.5 из 5 кг, недовоз 1.5'));
    expect(text, contains('❌ Не пришло:\n• Яйца — 30 шт'));
    expect(text, contains('➕ Сверх заявки:\n• Лимон — 1 кг'));
  });

  test('база версии 1 обновляется до версии 2 без потери данных', () async {
    final dir = await Directory.systemTemp.createTemp('akyl_mig');
    final file = File('${dir.path}/v1.sqlite');
    // Создаём базу текущей схемы и откатываем её к виду версии 1.
    var v1 = AppDatabase(NativeDatabase(file));
    final ops1 = OperationsDao(v1);
    final vid = await CatalogDao(v1).upsertVenue(code: '01', name: 'Центр');
    await ops1.addHistoryEntry(
        venueId: vid, kind: 'request', title: 'Старая заявка', body: 'x');
    await v1.customStatement('DROP TABLE document_lines');
    await v1.customStatement('ALTER TABLE history_entries DROP COLUMN ref_id');
    await v1.customStatement(
        'ALTER TABLE history_entries DROP COLUMN attachment_path');
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v2 = AppDatabase(NativeDatabase(file));
    final ops2 = OperationsDao(v2);
    final rows = await ops2.loadHistory(vid);
    expect(rows.single.title, 'Старая заявка');
    expect(rows.single.refId, isNull);
    // Новая таблица работает.
    final id = await ops2.addHistoryEntry(
        venueId: vid, kind: 'receipt', title: 'Приёмка', body: 'y',
        refId: rows.single.id,
        lines: const [DocumentLineInput(productName: 'Молоко', quantity: 1)]);
    expect((await ops2.loadDocumentLines(id)).single.productName, 'Молоко');
    final version = await v2.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 2);
    await v2.close();
    await dir.delete(recursive: true);
  });
}
