/// Не больше 10 распознаваний накладной в сутки на заведение.
class OcrQuota {
  static const int dailyLimit = 10;

  final String day;
  final int used;

  const OcrQuota({required this.day, required this.used});

  static String dayKey(DateTime now) {
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  factory OcrQuota.fresh(DateTime now) => OcrQuota(day: dayKey(now), used: 0);

  int get left => (dailyLimit - used).clamp(0, dailyLimit);

  bool get canRecognize => used < dailyLimit;

  OcrQuota consume() => OcrQuota(day: day, used: used + 1);

  Map<String, dynamic> toJson() => {'day': day, 'used': used};

  /// Чужой день обнуляет счётчик: лимит суточный.
  factory OcrQuota.fromJson(Map<String, dynamic>? json, DateTime now) {
    final today = dayKey(now);
    if (json == null || json['day']?.toString() != today) {
      return OcrQuota.fresh(now);
    }
    final used = (json['used'] as num?)?.toInt() ?? 0;
    return OcrQuota(day: today, used: used < 0 ? 0 : used);
  }
}
