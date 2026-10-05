import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/dao/catalog_dao.dart';
import 'package:horeca_app/features/auth/data/staff_pin_service.dart';
import 'package:horeca_app/features/backup/data/backup_service.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';

void main() {
  late AppDatabase db;
  late CatalogDao catalog;
  late String venueId;
  late StaffPinService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    catalog = CatalogDao(db);
    venueId = await catalog.upsertVenue(code: '01', name: 'Центр');
    service = StaffPinService(catalog, venueId);
  });
  tearDown(() => db.close());

  Future<String> addStaff(String name) =>
      catalog.upsertStaffMember(venueId: venueId, fullName: name);

  test('хранится только хеш, вход по личному PIN находит сотрудника', () async {
    final id = await addStaff('Айгуль');
    expect(await service.setPin(staffId: id, pin: '4821', role: 'admin'),
        isNull);
    final row = (await service.loadStaff()).single;
    expect(row.pinHash, isNot(contains('4821')));
    expect(row.pinSalt, isNotNull);
    expect(row.role, 'admin');
    expect((await service.match('4821'))?.id, id);
    expect(await service.match('4822'), isNull);
    expect(await service.hasAnyPersonalPin(), isTrue);
  });

  test('PIN не может совпадать с чужим или общим', () async {
    final a = await addStaff('Айгуль');
    final b = await addStaff('Бахыт');
    await service.setPin(staffId: a, pin: '1111', role: 'staff');
    expect(await service.setPin(staffId: b, pin: '1111', role: 'staff'),
        contains('занят'));
    expect(
        await service.setPin(
            staffId: b, pin: '2222', role: 'staff', sharedPins: ['2222']),
        contains('общим'));
    expect(await service.setPin(staffId: b, pin: '12', role: 'staff'),
        contains('4 цифры'));
  });

  test('переименование сотрудника не сбрасывает его PIN и роль', () async {
    final repo = SettingsRepository(catalog, venueId);
    await repo.ready;
    repo.addStaff('Настя');
    await repo.pendingStaffWrite;
    final id = repo.staffIdByName('Настя')!;
    await service.setPin(staffId: id, pin: '5555', role: 'admin');
    repo.updateStaff('Настя', 'Анастасия');
    await repo.pendingStaffWrite;
    final match = await service.match('5555');
    expect(match?.fullName, 'Анастасия');
    expect(match?.role, 'admin');
  });

  test('снятый PIN больше не пускает, роль сохраняется', () async {
    final id = await addStaff('Айгуль');
    await service.setPin(staffId: id, pin: '4821', role: 'admin');
    await service.clearPin(id, role: 'admin');
    expect(await service.match('4821'), isNull);
    expect((await service.loadStaff()).single.role, 'admin');
  });

  test('хеши личных PIN не попадают в файл бэкапа', () async {
    final id = await addStaff('Айгуль');
    await service.setPin(staffId: id, pin: '4821', role: 'admin');
    final backup = await BackupService.exportData(db);
    final staff = (backup['tables'] as Map)['staff_members'] as List;
    final row = staff.single as Map;
    expect(row['full_name'], 'Айгуль');
    expect(row['role'], 'admin');
    expect(row['pin_hash'], isNull);
    expect(row['pin_salt'], isNull);
  });
}
