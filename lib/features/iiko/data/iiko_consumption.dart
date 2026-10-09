import 'package:dio/dio.dart';
import 'package:horeca_app/features/supply/domain/consumption.dart';

class IikoConsumptionResult {
  final List<DishSale> sales;
  final Map<String, List<CardIngredient>> cards;
  final String? salesError;
  final String? cardsError;

  const IikoConsumptionResult({
    this.sales = const [],
    this.cards = const {},
    this.salesError,
    this.cardsError,
  });

  bool get hasSales => salesError == null;
}

/// Продажи и техкарты iiko Cloud.
/// Если метод не ответил, цифры расхода не подставляются.
class IikoConsumptionClient {
  final Dio _dio;
  static const _salesUrls = [
    'https://api-ru.iiko.services/api/reporting/v1/olap',
    'https://api-ru.iiko.services/api/reporting/v1/olap/get',
  ];
  static const _chartUrl =
      'https://api-ru.iiko.services/api/nomenclature/v1/assembly-chart/get';

  IikoConsumptionClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 40),
              sendTimeout: const Duration(seconds: 20),
            ));

  Future<IikoConsumptionResult> pull({
    required String token,
    required String organizationId,
    required DateTime from,
    required DateTime to,
    required Map<String, String> productNames,
  }) async {
    final sales = <DishSale>[];
    String? salesError;
    final chunks = _chunks(from, to);
    for (final chunk in chunks) {
      try {
        final body = await _salesChunk(token, organizationId, chunk.$1, chunk.$2);
        sales.addAll(parseOlapSales(body));
      } on DioException catch (error) {
        salesError = _message(error);
        break;
      }
    }
    if (salesError != null) {
      return IikoConsumptionResult(salesError: salesError);
    }

    Map<String, List<CardIngredient>> cards = const {};
    String? cardsError;
    try {
      final response = await _dio.post(
        _chartUrl,
        data: {
          'organizationId': organizationId,
          'from': _day(from),
          'to': _day(to),
          'dateFrom': _day(from),
          'dateTo': _day(to),
          'includeDeletedProducts': false,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      cards = parseAssemblyCharts(response.data, productNames);
      if (cards.isEmpty) {
        cardsError = 'iiko не отдал техкарты. Расход по ингредиентам не записан.';
      }
    } on DioException catch (error) {
      cardsError = _message(error);
    }
    return IikoConsumptionResult(
      sales: _mergeSales(sales),
      cards: cards,
      cardsError: cardsError,
    );
  }

  Future<dynamic> _salesChunk(
    String token,
    String organizationId,
    DateTime from,
    DateTime to,
  ) async {
    final payload = {
      'organizationId': organizationId,
      'organizationIds': [organizationId],
      'reportType': 'SALES',
      // День продажи нужен, чтобы расход лёг на свой день, а не одной
      // датой на весь срок (иначе пересчёт внутри срока вычитался дважды).
      'groupByRowFields': ['DishName', 'OpenDate.Typed'],
      'groupByColFields': <String>[],
      'aggregateFields': ['DishAmountInt'],
      'buildSummary': false,
      'filters': [
        {
          'name': 'OpenDate.Typed',
          'filterType': 'DateRange',
          'periodType': 'CUSTOM',
          'from': _stamp(from),
          'to': _stampEnd(to),
          'includeLow': true,
          'includeHigh': true,
        },
        {
          'name': 'OrderDeleted',
          'filterType': 'IncludeValues',
          'values': ['NOT_DELETED'],
        },
      ],
    };
    DioException? last;
    for (final url in _salesUrls) {
      try {
        final response = await _dio.post(
          url,
          data: payload,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return response.data;
      } on DioException catch (error) {
        last = error;
        if (error.response?.statusCode != 404) break;
      }
    }
    throw last ?? DioException(requestOptions: RequestOptions(path: _salesUrls.first));
  }

  String _message(DioException error) {
    final code = error.response?.statusCode;
    if (code == 403 || code == 401) {
      return 'iiko не открыл продажи этому ключу. Расход по чекам не записан.';
    }
    if (code == 404) {
      return 'У этого iiko нет отчёта продаж. Расход по чекам не записан.';
    }
    return 'iiko не ответил по расходу. Цифры не подставлены.';
  }
}

List<DishSale> _mergeSales(List<DishSale> sales) {
  final byKey = <(String, DateTime?), double>{};
  for (final sale in sales) {
    final key = (sale.name, sale.day);
    byKey[key] = (byKey[key] ?? 0) + sale.qty;
  }
  return [
    for (final entry in byKey.entries)
      DishSale(name: entry.key.$1, qty: entry.value, day: entry.key.$2),
  ];
}

List<(DateTime, DateTime)> _chunks(DateTime from, DateTime to) {
  final out = <(DateTime, DateTime)>[];
  var cursor = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
  while (!cursor.isAfter(end)) {
    final chunkEnd = cursor.add(const Duration(days: 30, hours: 23, minutes: 59));
    final limited = chunkEnd.isAfter(end) ? end : chunkEnd;
    out.add((cursor, limited));
    cursor = DateTime(limited.year, limited.month, limited.day).add(const Duration(days: 1));
  }
  return out;
}

String _day(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _stamp(DateTime value) => '${_day(value)}T00:00:00.000';

/// Конец дня: иначе последний день каждого куска выпадал из продаж.
String _stampEnd(DateTime value) => '${_day(value)}T23:59:59.999';
