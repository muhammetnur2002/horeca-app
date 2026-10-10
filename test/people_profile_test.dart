import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/people/data/people_repository.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';
import 'package:horeca_app/features/people/presentation/people_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WorkPlace job({
    required String id,
    required String venueName,
    required HospitalityRole role,
    required DateTime startedAt,
    DateTime? endedAt,
    bool confirmed = false,
  }) {
    return WorkPlace(
      id: id,
      venueName: venueName,
      role: role,
      startedAt: startedAt,
      endedAt: endedAt,
      confirmed: confirmed,
      confirmedByOwnerId: confirmed ? 'AKYL-OWNER001' : null,
    );
  }

  List<WorkPlace> confirmedJobs(int count, int daysEach) {
    final start = DateTime(2000, 1, 1);
    return List.generate(count, (index) {
      return job(
        id: 'c$index',
        venueName: 'Место $index',
        role: HospitalityRole.waiter,
        startedAt: start,
        endedAt: DateTime(start.year, start.month, start.day + daysEach),
        confirmed: true,
      );
    });
  }

  RankAssessment rankOf(List<WorkPlace> places) =>
      assessRank(places, now: DateTime(2030, 1, 1));

  Future<PeopleRepository> repo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return PeopleRepository(prefs);
  }

  test('постоянный ID не зависит от имени и переживает перезапуск', () async {
    final people = await repo();
    expect(people.createProfile('Айгуль', random: Random(1)), isNull);
    final id = people.state.me!.id;
    expect(RegExp(personIdPattern).hasMatch(id), isTrue);
    expect(people.createProfile('Другое имя', random: Random(2)), isNull);
    expect(people.rename('Айгуль К.'), isNull);
    expect(people.state.me!.id, id);
    expect(people.state.me!.name, 'Айгуль К.');

    final again = PeopleRepository(await SharedPreferences.getInstance());
    expect(again.state.me!.id, id);
    expect(again.state.me!.name, 'Айгуль К.');
  });

  test('специальность одна, даже если должность на нескольких местах', () {
    final now = DateTime(2026, 1, 1);
    final places = [
      job(
        id: '1',
        venueName: 'Первое',
        role: HospitalityRole.waiter,
        startedAt: DateTime(2024, 1, 1),
        endedAt: DateTime(2024, 7, 1),
      ),
      job(
        id: '2',
        venueName: 'Второе',
        role: HospitalityRole.waiter,
        startedAt: DateTime(2025, 1, 1),
        endedAt: DateTime(2025, 4, 1),
      ),
      job(
        id: '3',
        venueName: 'Бар',
        role: HospitalityRole.bartender,
        startedAt: DateTime(2020, 1, 1),
        endedAt: DateTime(2021, 1, 1),
      ),
      job(
        id: '4',
        venueName: 'Кухня',
        role: HospitalityRole.cook,
        startedAt: DateTime(2018, 1, 1),
        endedAt: DateTime(2021, 1, 1),
      ),
    ];

    final specs = collectSpecialties(places, now: now);
    expect(specs.map((item) => item.role).toList(), [
      HospitalityRole.waiter,
      HospitalityRole.bartender,
      HospitalityRole.cook,
    ]);
    expect(specs.first.placeCount, 2);
    expect(workplaceDays(places[0], now), 182);
    expect(workplaceDays(places[1], now), 90);
    expect(specs.first.totalDays, 272);
    expect(specs.first.level, ExperienceLevel.medium);
  });

  test('цвет полоски и подпись берутся из констант дней', () {
    expect(ExperienceBarThresholds.littleMaxDays, 180);
    expect(ExperienceBarThresholds.muchMinDays, 730);
    expect(experienceLevel(0), ExperienceLevel.little);
    expect(experienceLevel(179), ExperienceLevel.little);
    expect(experienceLevel(180), ExperienceLevel.medium);
    expect(experienceLevel(729), ExperienceLevel.medium);
    expect(experienceLevel(730), ExperienceLevel.much);
    expect(experienceLegend(), contains('180'));
    expect(experienceLegend(), contains('729'));
    expect(experienceLegend(), contains('730'));
    expect(experienceFill(730), 1);
  });

  test('текущая работа считается до сегодня, дата конца раньше начала даёт ноль', () {
    final open = job(
      id: 'open',
      venueName: 'Смена',
      role: HospitalityRole.barista,
      startedAt: DateTime(2026, 10, 1),
    );
    expect(workplaceDays(open, DateTime(2026, 10, 11)), 10);
    final backwards = job(
      id: 'back',
      venueName: 'Смена',
      role: HospitalityRole.barista,
      startedAt: DateTime(2026, 10, 11),
      endedAt: DateTime(2026, 10, 1),
    );
    expect(workplaceDays(backwards, DateTime(2026, 10, 20)), 0);
    expect(
      validateWorkplace(
        venueName: 'Смена',
        startedAt: DateTime(2026, 10, 11),
        endedAt: DateTime(2026, 10, 1),
      ),
      'Дата конца раньше даты начала.',
    );
  });

  test('рейтинг растёт только по подтверждённым местам и сумме дней', () {
    expect(RankThresholds.workerMinPlaces, 1);
    expect(RankThresholds.workerMinDays, 90);
    expect(RankThresholds.coolMinPlaces, 2);
    expect(RankThresholds.coolMinDays, 365);
    expect(RankThresholds.masterMinPlaces, 3);
    expect(RankThresholds.masterMinDays, 730);
    expect(RankThresholds.titanMinPlaces, 4);
    expect(RankThresholds.titanMinDays, 1460);
    expect(RankThresholds.legendMinPlaces, 5);
    expect(RankThresholds.legendMinDays, 2555);

    expect(rankOf(const []).rank, PersonRank.novice);
    expect(rankOf(confirmedJobs(1, 89)).rank, PersonRank.novice);
    expect(rankOf(confirmedJobs(1, 90)).rank, PersonRank.worker);
    expect(rankOf(confirmedJobs(1, 2555)).rank, PersonRank.worker);
    expect(rankOf(confirmedJobs(2, 182)).rank, PersonRank.worker);
    expect(rankOf(confirmedJobs(2, 365)).rank, PersonRank.cool);
    expect(rankOf(confirmedJobs(3, 200)).rank, PersonRank.cool);
    expect(rankOf(confirmedJobs(3, 730)).rank, PersonRank.master);
    expect(rankOf(confirmedJobs(4, 1460)).rank, PersonRank.titan);
    expect(rankOf(confirmedJobs(5, 511)).rank, PersonRank.legend);

    final unconfirmed = confirmedJobs(5, 1000)
        .map((place) => place.copyWith(confirmed: false, clearConfirmedBy: true))
        .toList();
    final fresh = rankOf(unconfirmed);
    expect(fresh.rank, PersonRank.novice);
    expect(fresh.reason, contains('подтверд'));
    expect(rankScaleCaption(), contains('2555'));
    expect(rankTitle(PersonRank.legend), 'Легенда');
    expect(rankTitle(PersonRank.worker), 'Работяга');
  });

  test('видео больше 50 МБ получает отказ до записи', () async {
    expect(AlbumLimits.maxVideoBytes, 50 * 1024 * 1024);
    expect(decideVideoUpload(AlbumLimits.maxVideoBytes).allowed, isTrue);
    final tooBig = decideVideoUpload(AlbumLimits.maxVideoBytes + 1);
    expect(tooBig.allowed, isFalse);
    expect(tooBig.message, AlbumLimits.videoTooLargeText);
    expect(tooBig.message, contains('50 МБ'));
    expect(decideVideoUpload(null).message, AlbumLimits.videoSizeUnknownText);

    final people = await repo();
    people.createProfile('Аня', random: Random(3));
    final error = people.addAlbumItem(
      kind: AlbumKind.video,
      localPath: '/tmp/huge.mp4',
      sizeBytes: AlbumLimits.maxVideoBytes + 1,
    );
    expect(error, AlbumLimits.videoTooLargeText);
    expect(people.state.me!.album, isEmpty);

    expect(
      people.addAlbumItem(
        kind: AlbumKind.photo,
        localPath: '/tmp/big.jpg',
        sizeBytes: AlbumLimits.maxVideoBytes + 10,
      ),
      isNull,
    );
    expect(people.state.me!.album, hasLength(1));
  });

  test('допуск не создаёт профиль и не подтверждает место', () async {
    final people = await repo();
    people.createProfile('Владелец', random: Random(4));
    final ownerId = people.state.me!.id;
    expect(people.addOwnedVenue('Кофейня Облако'), isNull);
    final venueId = people.state.ownedVenues.single.id;

    expect(
      people.createAccess(
        venueId: venueId,
        personName: '  Марат  Иванов ',
        position: HospitalityRole.waiter,
        permissions: const [VenueSection.requests, VenueSection.warehouse],
      ),
      isNull,
    );
    expect(people.state.me!.id, ownerId);
    expect(people.state.me!.workplaces, isEmpty);
    expect(people.state.accesses.single.personName, 'Марат Иванов');
    expect(people.state.accesses.single.createdByOwnerId, ownerId);

    expect(
      people.createAccess(
        venueId: venueId,
        personName: 'Без разделов',
        position: HospitalityRole.cook,
        permissions: const [],
      ),
      contains('раздел'),
    );
    expect(people.state.accesses, hasLength(1));

    people.addWorkplace(
      venueName: 'Кофейня Облако',
      role: HospitalityRole.barista,
      startedAt: DateTime(2024, 1, 1),
      endedAt: null,
    );
    final placeId = people.state.me!.workplaces.single.id;
    expect(people.state.accesses, hasLength(1));
    expect(people.confirmWorkplace(placeId), isNull);
    expect(people.state.me!.workplaces.single.confirmed, isTrue);
    expect(people.state.accesses, hasLength(1));

    final cleared = people.updateWorkplace(
      id: placeId,
      venueName: 'Другое место',
      role: HospitalityRole.barista,
      startedAt: DateTime(2024, 1, 1),
      endedAt: null,
    );
    expect(cleared, isTrue);
    expect(people.state.me!.workplaces.single.confirmed, isFalse);
    expect(
      people.confirmWorkplace(people.state.me!.workplaces.single.id),
      contains('владелец'),
    );
  });

  test('чужой владелец не выдаёт допуск, навык без повторов, JSON круглый', () async {
    final me = PersonProfile(
      id: createPersonId(Random(7)),
      name: 'Аня',
      photoPath: null,
      skills: const ['латте'],
      awards: const [Award(id: 'a1', title: 'Лучшая смена', note: '')],
      workplaces: [
        job(
          id: 'w1',
          venueName: 'Кафе',
          role: HospitalityRole.waiter,
          startedAt: DateTime(2022, 5, 1),
          endedAt: null,
          confirmed: true,
        ),
      ],
      album: [
        AlbumItem(
          id: 'm1',
          kind: AlbumKind.video,
          localPath: '/tmp/shift.mp4',
          sizeBytes: 1024,
          addedAt: DateTime.utc(2026, 1, 2, 3, 4),
        ),
      ],
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final snapshot = PeopleSnapshot(
      version: PeopleSnapshot.storageVersion,
      me: me,
      ownedVenues: [
        OwnedVenue(
          id: 'v1',
          name: 'Чужое',
          ownerProfileId: 'AKYL-NOTMINE1',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
      accesses: const [],
    );
    final encoded = jsonEncode(snapshot.toJson());
    final parsed = PeopleSnapshot.tryParse(jsonDecode(encoded));
    expect(parsed, isNotNull);
    expect(parsed!.me!.id, me.id);
    expect(parsed.me!.workplaces.single.workingNow, isTrue);
    expect(parsed.me!.workplaces.single.confirmed, isTrue);
    expect(parsed.me!.album.single.kind, AlbumKind.video);
    expect(parsed.me!.album.single.sizeBytes, 1024);

    SharedPreferences.setMockInitialValues({peoplePrefsKey: encoded});
    final prefs = await SharedPreferences.getInstance();
    final people = PeopleRepository(prefs);
    expect(
      people.createAccess(
        venueId: 'v1',
        personName: 'Кто-то',
        position: HospitalityRole.manager,
        permissions: const [VenueSection.shift],
      ),
      'Допуск создаёт только владелец этого заведения.',
    );
    expect(people.state.accesses, isEmpty);
    expect(people.addSkill('Латте'), 'Такой навык уже есть.');
    expect(people.state.me!.skills, ['латте']);
  });

  test('более новая запись на телефоне не затирается', () async {
    SharedPreferences.setMockInitialValues({
      peoplePrefsKey: '{"version":9,"secret":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final people = PeopleRepository(prefs);
    expect(people.createProfile('Аня'), contains('новее'));
    expect(prefs.getString(peoplePrefsKey), contains('"version":9'));
    expect(people.state.me, isNull);
  });

  test('раздел людей не подключён к PIN и к облачной синхронизации', () {
    final peopleDir = Directory('lib/features/people');
    final sources = peopleDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    expect(sources, isNotEmpty);
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(text.contains('auth_repository'), isFalse, reason: file.path);
      expect(text.contains('UserRole'), isFalse, reason: file.path);
      expect(text.contains('CloudSyncService'), isFalse, reason: file.path);
      expect(text.contains('scheduleSync'), isFalse, reason: file.path);
    }

    final cloud = File('lib/features/account/data/cloud_sync_service.dart').readAsStringSync();
    final backup = File('lib/features/backup/data/backup_service.dart').readAsStringSync();
    expect(cloud.contains(peoplePrefsKey), isFalse);
    expect(backup.contains(peoplePrefsKey), isFalse);

    // Две двери: профиль открывает дверь сотрудника, а не кнопка на главной
    // заведения. Заведение заходит в «Люди» только за выдачей доступа.
    final home = File('lib/features/home/presentation/home_screen.dart').readAsStringSync();
    expect(home.contains("label: 'Люди'"), isFalse);
    expect(home.contains("context.push('/people')"), isFalse);
    final routes = File('lib/app/routes.dart').readAsStringSync();
    final staffRouter = routes.substring(routes.indexOf('final staffRouter'));
    expect(staffRouter.contains('StaffShell()'), isTrue);
    final settings =
        File('lib/features/settings/presentation/tabs/app_settings_tab.dart').readAsStringSync();
    expect(settings.contains("context.push('/people/access')"), isTrue);
  });

  testWidgets('экран профиля показывает ID, рейтинг, одну специальность и пороги', (tester) async {
    final people = await repo();
    people.createProfile('Айгуль', random: Random(8));
    people.addOwnedVenue('Кофейня Облако');
    people.addWorkplace(
      venueName: 'Кофейня Облако',
      role: HospitalityRole.waiter,
      startedAt: DateTime(2024, 1, 1),
      endedAt: DateTime(2024, 7, 1),
    );
    people.confirmWorkplace(people.state.me!.workplaces.single.id);
    people.addWorkplace(
      venueName: 'Другое место',
      role: HospitalityRole.waiter,
      startedAt: DateTime(2025, 1, 1),
      endedAt: DateTime(2025, 4, 1),
    );
    people.addWorkplace(
      venueName: 'Бар Север',
      role: HospitalityRole.bartender,
      startedAt: DateTime(2020, 1, 1),
      endedAt: DateTime(2021, 1, 1),
    );
    people.addWorkplace(
      venueName: 'Кухня Юг',
      role: HospitalityRole.cook,
      startedAt: DateTime(2018, 1, 1),
      endedAt: DateTime(2021, 1, 1),
    );
    final id = people.state.me!.id;
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: PeopleProfileScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Айгуль'), findsOneWidget);
    expect(find.text(id), findsOneWidget);
    expect(find.byKey(const Key('person-rank-title')), findsOneWidget);
    expect(find.text('Работяга'), findsOneWidget);
    expect(find.textContaining('182 дня'), findsWidgets);
    expect(find.byKey(const Key('specialty-waiter')), findsOneWidget);
    expect(find.byKey(const Key('specialty-bartender')), findsOneWidget);
    expect(find.byKey(const Key('specialty-cook')), findsOneWidget);
    expect(find.byKey(const Key('specialty-barista')), findsNothing);
    expect(find.text('средне'), findsWidgets);
    expect(find.text('много'), findsOneWidget);
    expect(find.text(experienceLegend()), findsOneWidget);
    expect(find.text(rankScaleCaption()), findsOneWidget);
    expect(find.text('работаю сейчас'), findsNothing);
  });
}
