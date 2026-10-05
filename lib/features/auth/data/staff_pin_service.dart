/// Личные PIN-коды сотрудников.
///
/// Общие PIN администратора и сотрудника продолжают работать как раньше;
/// личный PIN добавляется к ним и говорит приложению, кто именно вошёл —
/// чтобы приёмка, инвентаризация и закрытие смены были подписаны.
/// В базе хранится только хеш PIN с солью.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/core/db/db_providers.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

abstract final class PinHasher {
  static final _rnd = Random.secure();

  static String newSalt() =>
      base64Url.encode(List<int>.generate(16, (_) => _rnd.nextInt(256)));

  static String hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool matches(String pin, String? hash, String? salt) =>
      hash != null && salt != null && PinHasher.hash(pin, salt) == hash;
}

class StaffPinService {
  final CatalogDao _dao;
  final String _venueId;

  StaffPinService(this._dao, this._venueId);

  Future<List<StaffMemberRow>> loadStaff() => _dao.loadStaff(_venueId);

  /// Есть ли у кого-то из сотрудников заведения личный PIN.
  Future<bool> hasAnyPersonalPin() async =>
      (await loadStaff()).any((s) => s.pinHash != null && s.isActive);

  /// Сотрудник с таким личным PIN или null.
  Future<StaffMemberRow?> match(String pin) async {
    if (pin.length != 4) return null;
    for (final s in await loadStaff()) {
      if (s.isActive && PinHasher.matches(pin, s.pinHash, s.pinSalt)) return s;
    }
    return null;
  }

  /// Задаёт личный PIN и роль. Возвращает текст ошибки или null.
  /// [sharedPins] — общие PIN заведения: личный не должен с ними совпадать,
  /// иначе непонятно, кто вошёл.
  Future<String?> setPin({
    required String staffId,
    required String pin,
    required String role,
    Iterable<String?> sharedPins = const [],
  }) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return 'PIN — ровно 4 цифры';
    if (sharedPins.contains(pin)) {
      return 'Этот PIN совпадает с общим PIN заведения';
    }
    for (final s in await loadStaff()) {
      if (s.id != staffId && PinHasher.matches(pin, s.pinHash, s.pinSalt)) {
        return 'Этот PIN уже занят другим сотрудником';
      }
    }
    final salt = PinHasher.newSalt();
    await _dao.setStaffPin(staffId,
        role: role, pinHash: PinHasher.hash(pin, salt), pinSalt: salt);
    return null;
  }

  Future<void> setRole(String staffId, String role) async {
    final staff = (await loadStaff()).where((s) => s.id == staffId);
    if (staff.isEmpty) return;
    await _dao.setStaffPin(staffId,
        role: role, pinHash: staff.first.pinHash, pinSalt: staff.first.pinSalt);
  }

  Future<void> clearPin(String staffId, {required String role}) =>
      _dao.setStaffPin(staffId, role: role);
}

final staffPinServiceProvider = Provider<StaffPinService>((ref) {
  return StaffPinService(
    ref.watch(catalogDaoProvider),
    ref.watch(activeVenueIdProvider),
  );
});
