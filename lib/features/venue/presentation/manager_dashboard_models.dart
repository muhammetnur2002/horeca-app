/// Модели данных дашборда управляющего.
/// Вынесены из manager_dashboard_screen.dart.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Данные одного заведения на дашборде: выручка сегодня/вчера/за неделю,
/// списания, ошибка загрузки (если не удалось получить данные из облака).
class VenueSnapshot {
  final Venue venue;
  final double todayRevenue;
  final double yesterdayRevenue;
  final int shiftsToday;
  final Map<String, int> writeOffsTotal;
  // Для текстовых инсайтов — сравнение последних 7 дней с предыдущими 7.
  final double weekRevenue;
  final double prevWeekRevenue;
  final Map<String, int> weekWriteOffs;
  final Map<String, int> prevWeekWriteOffs;
  final String? error;

  VenueSnapshot({
    required this.venue,
    required this.todayRevenue,
    required this.yesterdayRevenue,
    required this.shiftsToday,
    required this.writeOffsTotal,
    this.weekRevenue = 0,
    this.prevWeekRevenue = 0,
    this.weekWriteOffs = const {},
    this.prevWeekWriteOffs = const {},
    this.error,
  });
}

/// Один пункт текстовой сводки для управляющего — короткое предложение
/// человеческим языком вместо голых цифр, плюс цвет/иконка по смыслу
/// (хорошая новость / повод проверить).
class Insight {
  final String text;
  final IconData icon;
  final Color color;
  const Insight({required this.text, required this.icon, required this.color});
}
