import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/features/account/data/cloud_sync_merge.dart';

void main() {
  test('без локальных правок побеждает облако', () {
    final merged = mergeSyncValue(
      key: 'history_data',
      local: jsonEncode([
        {'id': 'local', 'title': 'своё'}
      ]),
      cloud: jsonEncode([
        {'id': 'cloud', 'title': 'чужое'}
      ]),
      localPending: false,
    );
    expect(jsonDecode(merged!), [
      {'id': 'cloud', 'title': 'чужое'}
    ]);
  });

  test('история с двух телефонов соединяется по id', () {
    final merged = mergeSyncValue(
      key: 'history_data',
      local: jsonEncode([
        {'id': 'a', 'title': 'заявка'}
      ]),
      cloud: jsonEncode([
        {'id': 'b', 'title': 'инвентаризация'}
      ]),
      localPending: true,
    );
    final ids = (jsonDecode(merged!) as List).map((e) => e['id']).toList();
    expect(ids, ['b', 'a']);
  });

  test('один и тот же товар не теряется, локальное имя остаётся', () {
    final merged = mergeSyncValue(
      key: 'settings_data',
      local: jsonEncode({
        'products': [
          {'id': '1', 'name': 'Молоко 3%'}
        ],
        'staff': ['Аня'],
      }),
      cloud: jsonEncode({
        'products': [
          {'id': '1', 'name': 'Молоко'},
          {'id': '2', 'name': 'Сахар'}
        ],
        'staff': ['Боря'],
        'currency': '₸',
      }),
      localPending: true,
    );
    final data = jsonDecode(merged!) as Map<String, dynamic>;
    expect(data['products'], [
      {'id': '1', 'name': 'Молоко 3%'},
      {'id': '2', 'name': 'Сахар'},
    ]);
    expect(data['staff'], ['Аня', 'Боря']);
    expect(data['currency'], '₸');
  });

  test('остатки соединяются, локальное число важнее', () {
    final merged = mergeSyncValue(
      key: 'current_stock_levels',
      local: jsonEncode({'coffee': 1}),
      cloud: jsonEncode({'coffee': 9, 'milk': 2}),
      localPending: true,
    );
    expect(jsonDecode(merged!), {'coffee': 1, 'milk': 2});
  });
}
