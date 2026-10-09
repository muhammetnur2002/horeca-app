import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:horeca_app/features/supply/domain/stock_ledger.dart';

/// Зелёный — много, жёлтый — мало, красный — плохо, без заливки — норма.
Future<Uint8List> buildStockExcel({
  required List<StockReportRow> rows,
  required DateTime from,
  required DateTime to,
}) async {
  final excel = Excel.createExcel();
  excel.rename('Sheet1', 'Остатки');
  final sheet = excel['Остатки'];
  const headers = [
    'Товар',
    'Ед.',
    'На начало',
    'Приход',
    'Расход',
    'Списания',
    'Остаток',
    'Метка',
  ];
  for (var column = 0; column < headers.length; column++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0));
    cell.value = TextCellValue(headers[column]);
    cell.cellStyle = CellStyle(bold: true);
  }
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final values = [
      row.name,
      row.unit,
      _qty(row.opening),
      _qty(row.incoming),
      _qty(row.consumption),
      _qty(row.writeOff),
      _qty(row.closing),
      stockMarkLabel(row.mark),
    ];
    final fill = _fill(row.mark);
    for (var column = 0; column < values.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: i + 1),
      );
      cell.value = TextCellValue(values[column]);
      if (fill != null) {
        cell.cellStyle = CellStyle(backgroundColorHex: fill);
      }
    }
  }
  final note = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rows.length + 2),
  );
  note.value = TextCellValue(
    'Зелёный — больше чем в ${StockThresholds.highMultiple.toStringAsFixed(0)} раза минимума. '
    'Жёлтый — ниже минимума. Красный — ноль или минус. Без метки — норма. '
    'Если в периоде была инвентаризация, остаток взят из подсчёта.',
  );
  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Не удалось собрать Excel');
  }
  return Uint8List.fromList(bytes);
}

String stockExcelFileName(DateTime from, DateTime to) =>
    'akyl_ostatki_${_day(from)}_${_day(to)}.xlsx';

ExcelColor? _fill(StockMark mark) {
  switch (mark) {
    case StockMark.high:
      return ExcelColor.green100;
    case StockMark.low:
      return ExcelColor.yellow100;
    case StockMark.bad:
      return ExcelColor.red100;
    case StockMark.stable:
      return null;
  }
}

String _qty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _day(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
