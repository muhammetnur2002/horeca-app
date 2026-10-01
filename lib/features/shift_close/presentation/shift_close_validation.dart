/// Проверки перед переходом на следующий шаг закрытия смены. Вынесены из
/// shift_close_screen.dart, чтобы не раздувать его.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';

/// Возвращает текст предупреждения, если шаг [step] заполнен некорректно,
/// или null, если можно переходить дальше.
String? validateShiftStep({
  required int step,
  required Set<String> selectedStaff,
  required List<DessertItem> desserts,
  required TextEditingController qrController,
  required TextEditingController cardController,
  required TextEditingController cashController,
  required TextEditingController morningCashController,
  required TextEditingController eveningCashController,
}) {
  if (step == 0) {
    if (selectedStaff.isEmpty) {
      return 'Отметьте хотя бы одного сотрудника';
    }
    // Проверки "остаток десертов > 0" здесь сознательно нет: если все
    // десерты распроданы, нули — правильные данные, а раньше из-за этой
    // проверки смену было невозможно закрыть.
  }
  if (step == 1) {
    if (qrController.text.trim().isEmpty) {
      return 'Укажите сумму по QR-коду (или 0, если не было)';
    }
    if (cardController.text.trim().isEmpty) {
      return 'Укажите сумму по карте (или 0, если не было)';
    }
    if (cashController.text.trim().isEmpty) {
      return 'Укажите сумму наличными (или 0, если не было)';
    }
    final qr = double.tryParse(qrController.text) ?? 0;
    final card = double.tryParse(cardController.text) ?? 0;
    final cash = double.tryParse(cashController.text) ?? 0;
    if (qr == 0 && card == 0 && cash == 0) {
      return 'Хотя бы один способ оплаты должен быть больше нуля';
    }
  }
  if (step == 2) {
    final morning = double.tryParse(morningCashController.text) ?? 0;
    final evening = double.tryParse(eveningCashController.text) ?? 0;
    if (morning == 0 && evening == 0) {
      return 'Заполните наличные в кассе';
    }
  }
  return null;
}
