import 'package:horeca_app/features/people/domain/people_models.dart';

/// Пороги цвета полоски стажа, в днях.
/// Подпись на экране профиля собирается из этих чисел.
/// Красная — строго меньше [littleMaxDays].
/// Жёлтая — от [littleMaxDays] до дня перед [muchMinDays].
/// Зелёная — от [muchMinDays] и дальше.
class ExperienceBarThresholds {
  static const int littleMaxDays = 180;
  static const int muchMinDays = 730;
}

enum ExperienceLevel { little, medium, much }

/// Пороги рейтинга: и число подтверждённых мест, и сумма дней по ним.
/// Оба условия нужны сразу. Экран показывает шкалу из этих чисел.
class RankThresholds {
  static const int workerMinPlaces = 1;
  static const int workerMinDays = 90;

  static const int coolMinPlaces = 2;
  static const int coolMinDays = 365;

  static const int masterMinPlaces = 3;
  static const int masterMinDays = 730;

  static const int titanMinPlaces = 4;
  static const int titanMinDays = 1460;

  static const int legendMinPlaces = 5;
  static const int legendMinDays = 2555;
}

/// Видео в альбоме. Проверка размера до копирования файла.
class AlbumLimits {
  static const int maxVideoBytes = 50 * 1024 * 1024;

  static String get videoTooLargeText {
    final megabytes = maxVideoBytes ~/ (1024 * 1024);
    return 'Видео больше $megabytes МБ. В альбом можно добавить ролик до $megabytes МБ.';
  }

  static const videoSizeUnknownText =
      'Не удалось проверить размер видео. Файл не добавлен.';

  static const horecaOnlyTitle = 'Только про общепит';
  static const horecaOnlyBody =
      'В альбом можно добавить фото или видео про работу в общепите: кухня, бар, зал, смена, блюдо, команда.';
  static const horecaConfirm = 'Это про общепит';
  static const horecaCancel = 'Отмена';
}

class VideoSizeDecision {
  final bool allowed;
  final String? message;

  const VideoSizeDecision._(this.allowed, this.message);

  static const allowedOk = VideoSizeDecision._(true, null);
}

/// [sizeBytes] == null, если размер прочитать не вышло.
VideoSizeDecision decideVideoUpload(int? sizeBytes) {
  if (sizeBytes == null || sizeBytes < 0) {
    return const VideoSizeDecision._(false, AlbumLimits.videoSizeUnknownText);
  }
  if (sizeBytes > AlbumLimits.maxVideoBytes) {
    return VideoSizeDecision._(false, AlbumLimits.videoTooLargeText);
  }
  return VideoSizeDecision.allowedOk;
}

String russianCount(int value, String one, String few, String many) {
  final abs = value.abs();
  final mod100 = abs % 100;
  final mod10 = abs % 10;
  final word = (mod100 >= 11 && mod100 <= 14)
      ? many
      : mod10 == 1
          ? one
          : (mod10 >= 2 && mod10 <= 4)
              ? few
              : many;
  return '$value $word';
}

String countDays(int days) => russianCount(days, 'день', 'дня', 'дней');

String countPlaces(int places) => russianCount(places, 'место', 'места', 'мест');

String normalizeVenueName(String name) => tidyText(name).toLowerCase();

String skillKey(String skill) => tidyText(skill).toLowerCase();

int workplaceDays(WorkPlace place, DateTime now) {
  final start = dateOnly(place.startedAt);
  final end = dateOnly(place.endedAt ?? now);
  if (end.isBefore(start)) return 0;
  // Календарные сутки, не «24 часа». Иначе летнее время
  // уменьшает стаж на день и сдвигает цвет полоски и рейтинг.
  return DateTime.utc(end.year, end.month, end.day)
      .difference(DateTime.utc(start.year, start.month, start.day))
      .inDays;
}

ExperienceLevel experienceLevel(int days) {
  if (days < ExperienceBarThresholds.littleMaxDays) return ExperienceLevel.little;
  if (days < ExperienceBarThresholds.muchMinDays) return ExperienceLevel.medium;
  return ExperienceLevel.much;
}

String experienceLevelLabel(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.little:
      return 'мало';
    case ExperienceLevel.medium:
      return 'средне';
    case ExperienceLevel.much:
      return 'много';
  }
}

/// Доля полоски. На зелёном пороге полоска полная.
double experienceFill(int days) {
  final cap = ExperienceBarThresholds.muchMinDays;
  if (cap <= 0) return 0;
  if (days <= 0) return 0.04;
  final fraction = days / cap;
  if (fraction < 0.04) return 0.04;
  if (fraction > 1) return 1;
  return fraction;
}

String experienceLegend() {
  final little = ExperienceBarThresholds.littleMaxDays;
  final much = ExperienceBarThresholds.muchMinDays;
  final yellowUntil = much - 1;
  return 'Красная — меньше $little дней. '
      'Жёлтая — от $little до $yellowUntil дней. '
      'Зелёная — от $much дней.';
}

class SpecialtyExperience {
  final HospitalityRole role;
  final int placeCount;
  final int totalDays;
  final ExperienceLevel level;

  const SpecialtyExperience({
    required this.role,
    required this.placeCount,
    required this.totalDays,
    required this.level,
  });
}

/// Каждая должность один раз. Дни всех мест этой должности складываются,
/// в том числе неподтверждённые. Текущая работа считается до [now].
List<SpecialtyExperience> collectSpecialties(
  List<WorkPlace> places, {
  required DateTime now,
}) {
  final result = <SpecialtyExperience>[];
  for (final role in HospitalityRole.values) {
    final matched = places.where((place) => place.role == role).toList();
    if (matched.isEmpty) continue;
    final days = matched.fold<int>(0, (sum, place) => sum + workplaceDays(place, now));
    result.add(SpecialtyExperience(
      role: role,
      placeCount: matched.length,
      totalDays: days,
      level: experienceLevel(days),
    ));
  }
  return result;
}

enum PersonRank { novice, worker, cool, master, titan, legend }

const personRankTitles = <PersonRank, String>{
  PersonRank.novice: 'Новичок',
  PersonRank.worker: 'Работяга',
  PersonRank.cool: 'Крутой',
  PersonRank.master: 'Мастер',
  PersonRank.titan: 'Титан',
  PersonRank.legend: 'Легенда',
};

String rankTitle(PersonRank rank) => personRankTitles[rank]!;

class RankAssessment {
  final PersonRank rank;
  final String title;
  final String reason;
  final int confirmedPlaces;
  final int confirmedDays;

  const RankAssessment({
    required this.rank,
    required this.title,
    required this.reason,
    required this.confirmedPlaces,
    required this.confirmedDays,
  });
}

bool rankMeets(int places, int days, int minPlaces, int minDays) =>
    places >= minPlaces && days >= minDays;

/// Рейтинг только по подтверждённым местам и сумме дней на них.
RankAssessment assessRank(List<WorkPlace> places, {required DateTime now}) {
  final confirmed = places.where((place) => place.confirmed).toList();
  final placeCount = confirmed.length;
  final days = confirmed.fold<int>(0, (sum, place) => sum + workplaceDays(place, now));

  PersonRank rank = PersonRank.novice;
  if (rankMeets(placeCount, days, RankThresholds.legendMinPlaces, RankThresholds.legendMinDays)) {
    rank = PersonRank.legend;
  } else if (rankMeets(placeCount, days, RankThresholds.titanMinPlaces, RankThresholds.titanMinDays)) {
    rank = PersonRank.titan;
  } else if (rankMeets(placeCount, days, RankThresholds.masterMinPlaces, RankThresholds.masterMinDays)) {
    rank = PersonRank.master;
  } else if (rankMeets(placeCount, days, RankThresholds.coolMinPlaces, RankThresholds.coolMinDays)) {
    rank = PersonRank.cool;
  } else if (rankMeets(placeCount, days, RankThresholds.workerMinPlaces, RankThresholds.workerMinDays)) {
    rank = PersonRank.worker;
  }

  return RankAssessment(
    rank: rank,
    title: rankTitle(rank),
    reason: _rankReason(
      rank: rank,
      places: places,
      confirmedPlaces: placeCount,
      confirmedDays: days,
    ),
    confirmedPlaces: placeCount,
    confirmedDays: days,
  );
}

String _rankReason({
  required PersonRank rank,
  required List<WorkPlace> places,
  required int confirmedPlaces,
  required int confirmedDays,
}) {
  if (rank == PersonRank.novice) {
    if (places.isEmpty) {
      return 'Мест работы пока нет. Уровень считается по местам, которые подтвердил владелец.';
    }
    if (confirmedPlaces == 0) {
      return 'Места уже есть. Уровень ждёт, пока владелец заведения их подтвердит.';
    }
    final needPlaces = countPlaces(RankThresholds.workerMinPlaces);
    final needDays = countDays(RankThresholds.workerMinDays);
    final havePlaces = countPlaces(confirmedPlaces);
    final haveDays = countDays(confirmedDays);
    return 'Сейчас $havePlaces и $haveDays. Для «Работяги» нужно $needPlaces и $needDays.';
  }
  final havePlaces = countPlaces(confirmedPlaces);
  final haveDays = countDays(confirmedDays);
  return '$havePlaces и $haveDays по сумме подтверждённого стажа.';
}

String rankScaleCaption() {
  String step(String title, int places, int days) =>
      '$title — ${countPlaces(places)} и ${countDays(days)}';
  return 'Шкала по подтверждённым местам и сумме дней: '
      '${step('Работяга', RankThresholds.workerMinPlaces, RankThresholds.workerMinDays)}, '
      '${step('Крутой', RankThresholds.coolMinPlaces, RankThresholds.coolMinDays)}, '
      '${step('Мастер', RankThresholds.masterMinPlaces, RankThresholds.masterMinDays)}, '
      '${step('Титан', RankThresholds.titanMinPlaces, RankThresholds.titanMinDays)}, '
      '${step('Легенда', RankThresholds.legendMinPlaces, RankThresholds.legendMinDays)}.';
}

bool sameWorkplaceClaim(WorkPlace current, {
  required String venueName,
  required HospitalityRole role,
  required DateTime startedAt,
  required DateTime? endedAt,
}) {
  final sameEnd = current.endedAt == null
      ? endedAt == null
      : endedAt != null && dateOnly(current.endedAt!) == dateOnly(endedAt);
  return normalizeVenueName(current.venueName) == normalizeVenueName(venueName) &&
      current.role == role &&
      dateOnly(current.startedAt) == dateOnly(startedAt) &&
      sameEnd;
}

String? validateWorkplace({
  required String venueName,
  required DateTime startedAt,
  required DateTime? endedAt,
}) {
  if (tidyText(venueName).isEmpty) return 'Напишите название места.';
  if (tidyText(venueName).length > 80) return 'Название места короче 80 знаков.';
  if (endedAt != null && dateOnly(endedAt).isBefore(dateOnly(startedAt))) {
    return 'Дата конца раньше даты начала.';
  }
  return null;
}

String? validatePersonName(String name, {required String emptyText}) {
  final tidy = tidyText(name);
  if (tidy.isEmpty) return emptyText;
  if (tidy.length > 60) return 'Имя короче 60 знаков.';
  return null;
}

String? validateSkill(String skill, List<String> existing) {
  final tidy = tidyText(skill);
  if (tidy.isEmpty) return 'Напишите навык.';
  if (tidy.length > 40) return 'Навык короче 40 знаков.';
  final key = skillKey(tidy);
  if (existing.any((item) => skillKey(item) == key)) {
    return 'Такой навык уже есть.';
  }
  return null;
}

String? validateAwardTitle(String title) {
  final tidy = tidyText(title);
  if (tidy.isEmpty) return 'Напишите название награды.';
  if (tidy.length > 60) return 'Название короче 60 знаков.';
  return null;
}

enum AccessDraftError { notOwner, emptyName, nameTooLong, noPermissions, venueMissing }

/// Допуск создаёт только профиль, которому принадлежит это заведение.
/// Свой личный профиль при этом не превращается в допуск.
AccessDraftError? validateAccessDraft({
  required PersonProfile? owner,
  required OwnedVenue? venue,
  required String personName,
  required List<VenueSection> permissions,
}) {
  if (owner == null || venue == null) return AccessDraftError.venueMissing;
  if (venue.ownerProfileId != owner.id) return AccessDraftError.notOwner;
  if (tidyText(personName).isEmpty) return AccessDraftError.emptyName;
  if (tidyText(personName).length > 60) return AccessDraftError.nameTooLong;
  if (permissions.isEmpty) return AccessDraftError.noPermissions;
  return null;
}

String accessErrorText(AccessDraftError error) {
  switch (error) {
    case AccessDraftError.notOwner:
      return 'Допуск создаёт только владелец этого заведения.';
    case AccessDraftError.emptyName:
      return 'Напишите имя человека.';
    case AccessDraftError.nameTooLong:
      return 'Имя короче 60 знаков.';
    case AccessDraftError.noPermissions:
      return 'Отметьте хотя бы один раздел, который человеку можно открывать.';
    case AccessDraftError.venueMissing:
      return 'Сначала запишите заведение на свой ID.';
  }
}

bool canConfirmWorkplace({
  required PersonProfile me,
  required WorkPlace place,
  required List<OwnedVenue> ownedVenues,
}) {
  if (place.confirmed) return false;
  final needle = normalizeVenueName(place.venueName);
  return ownedVenues.any(
    (venue) =>
        venue.ownerProfileId == me.id && normalizeVenueName(venue.name) == needle,
  );
}

String? validateOwnedVenueName(String name, List<OwnedVenue> existing) {
  final tidy = tidyText(name);
  if (tidy.isEmpty) return 'Напишите название заведения.';
  if (tidy.length > 80) return 'Название короче 80 знаков.';
  final key = normalizeVenueName(tidy);
  if (existing.any((venue) => normalizeVenueName(venue.name) == key)) {
    return 'Такое заведение уже записано на вас.';
  }
  return null;
}
