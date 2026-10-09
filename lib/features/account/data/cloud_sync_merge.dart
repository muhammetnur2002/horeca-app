import 'dart:convert';

/// Соединяет локальную и облачную копию одного ключа.
///
/// Если локальных правок не было, побеждает облако: оно новее по updatedAt.
/// Если правки были и ещё не уехали, списки соединяются по id, чтобы товар
/// или запись истории с другого телефона не пропадали. При одинаковом id
/// остаётся локальная версия — её пользователь только что менял.
String? mergeSyncValue({
  required String key,
  required String? local,
  required String? cloud,
  required bool localPending,
}) {
  if (cloud == null) return local;
  if (local == null || local.isEmpty) return cloud;
  if (!localPending) return cloud;
  try {
    final localJson = jsonDecode(local);
    final cloudJson = jsonDecode(cloud);
    switch (key) {
      case 'history_data':
        return jsonEncode(_mergeById(cloudJson, localJson));
      case 'shift_records':
        return jsonEncode(_mergeShifts(cloudJson, localJson));
      case 'settings_data':
        return jsonEncode(_mergeSettings(cloudJson, localJson));
      case 'notification_data':
        return jsonEncode(_mergeNotifications(cloudJson, localJson));
      case 'current_stock_levels':
        return jsonEncode(_mergeMaps(cloudJson, localJson));
      case 'supply_requests':
      case 'goods_receipts':
      case 'stock_moves':
        return jsonEncode(_mergeById(cloudJson, localJson));
      case 'ocr_quota':
        return jsonEncode(_mergeQuota(cloudJson, localJson));
      case 'custom_inventory_template':
        return local;
      default:
        return local;
    }
  } catch (_) {
    return local;
  }
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> _mergeById(dynamic cloud, dynamic local) {
  final byId = <String, dynamic>{};
  final order = <String>[];
  void take(dynamic item, {required bool overwrite}) {
    if (item is! Map) return;
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;
    if (!byId.containsKey(id)) order.add(id);
    if (!byId.containsKey(id) || overwrite) {
      byId[id] = Map<String, dynamic>.from(item);
    }
  }

  for (final item in _asList(cloud)) {
    take(item, overwrite: false);
  }
  for (final item in _asList(local)) {
    take(item, overwrite: true);
  }
  return [for (final id in order) byId[id]];
}

List<dynamic> _mergeShifts(dynamic cloud, dynamic local) {
  String signature(Map item) => jsonEncode({
        'date': item['date'],
        'revenue': item['revenue'],
        'qr': item['qr'],
        'card': item['card'],
        'cash': item['cash'],
        'morningCash': item['morningCash'],
        'eveningCash': item['eveningCash'],
        'writeOffs': item['writeOffs'],
      });

  final seen = <String>{};
  final out = <dynamic>[];
  void take(dynamic item) {
    if (item is! Map) return;
    final map = Map<String, dynamic>.from(item);
    final key = signature(map);
    if (seen.add(key)) out.add(map);
  }

  for (final item in _asList(cloud)) {
    take(item);
  }
  for (final item in _asList(local)) {
    take(item);
  }
  return out;
}

Map<String, dynamic> _mergeSettings(dynamic cloudRaw, dynamic localRaw) {
  final cloud = _asMap(cloudRaw);
  final local = _asMap(localRaw);
  final result = Map<String, dynamic>.from(local);
  for (final key in [
    'establishmentName',
    'currency',
    'logoPath',
    'showShiftDesserts',
  ]) {
    if (!result.containsKey(key) && cloud.containsKey(key)) {
      result[key] = cloud[key];
    }
  }
  result['departments'] = _mergeById(cloud['departments'], local['departments']);
  result['categories'] = _mergeById(cloud['categories'], local['categories']);
  result['products'] = _mergeById(cloud['products'], local['products']);
  result['staff'] = _mergeStaff(cloud['staff'], local['staff']);
  return result;
}

List<String> _mergeStaff(dynamic cloud, dynamic local) {
  final seen = <String>{};
  final out = <String>[];
  for (final name in [..._asList(local), ..._asList(cloud)]) {
    if (name is String && name.isNotEmpty && seen.add(name)) out.add(name);
  }
  return out;
}

Map<String, dynamic> _mergeNotifications(dynamic cloudRaw, dynamic localRaw) {
  final cloud = _asMap(cloudRaw);
  final local = _asMap(localRaw);
  return {
    'productReminders':
        _mergeById(cloud['productReminders'], local['productReminders']),
    'inventoryReminder':
        local['inventoryReminder'] ?? cloud['inventoryReminder'] ?? {},
  };
}

Map<String, dynamic> _mergeQuota(dynamic cloudRaw, dynamic localRaw) {
  final cloud = _asMap(cloudRaw);
  final local = _asMap(localRaw);
  final cloudDay = cloud['day']?.toString() ?? '';
  final localDay = local['day']?.toString() ?? '';
  if (cloudDay == localDay) {
    final cloudUsed = (cloud['used'] as num?)?.toInt() ?? 0;
    final localUsed = (local['used'] as num?)?.toInt() ?? 0;
    return {
      'day': localDay,
      'used': cloudUsed > localUsed ? cloudUsed : localUsed,
    };
  }
  if (cloudDay.compareTo(localDay) > 0) return cloud;
  return local;
}

Map<String, dynamic> _mergeMaps(dynamic cloudRaw, dynamic localRaw) {
  final result = _asMap(cloudRaw);
  result.addAll(_asMap(localRaw));
  return result;
}
