/// Переключение между 4 шагами экрана "Закрытие смены" по индексу текущего
/// шага. Вынесено из shift_close_screen.dart, чтобы не раздувать его
/// build().
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_step1_shift.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_step2_payment.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_step3_cash.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_step4_summary.dart';

Widget buildShiftCurrentStep({
  required int step,
  required BuildContext context,
  required WidgetRef ref,
  required StateSetter setState,
  required bool Function() isMounted,
  required bool isDark,
  required int totalSteps,
  required String currency,
  required Set<String> selectedStaff,
  required List<DessertItem> desserts,
  required bool dessertsLoaded,
  required List<ManualWriteOff> manualWriteOffs,
  required TextEditingController dessertSearchController,
  required String dessertSearch,
  required ValueChanged<String> onDessertSearchChanged,
  required void Function(List<DessertItem>) onDessertsLoaded,
  required TextEditingController qrController,
  required TextEditingController cardController,
  required TextEditingController cashController,
  required TextEditingController manualController,
  required TextEditingController morningCashController,
  required TextEditingController eveningCashController,
  required TextEditingController inkassController,
  required bool hasInkass,
  required void Function(bool) onHasInkassChanged,
  required double autoTotal,
  required double finalTotal,
  required double tomorrowCash,
  required VoidCallback onSubmit,
}) {
  switch (step) {
    case 0:
      return buildShiftStep1(
        context: context,
        ref: ref,
        setState: setState,
        isDark: isDark,
        totalSteps: totalSteps,
        selectedStaff: selectedStaff,
        desserts: desserts,
        dessertsLoaded: dessertsLoaded,
        manualWriteOffs: manualWriteOffs,
        dessertSearchController: dessertSearchController,
        dessertSearch: dessertSearch,
        onDessertSearchChanged: onDessertSearchChanged,
        onDessertsLoaded: (loaded) {
          if (!isMounted()) return;
          setState(() {
            onDessertsLoaded(loaded);
          });
        },
      );
    case 1:
      return buildShiftStep2(
        setState: setState,
        isDark: isDark,
        totalSteps: totalSteps,
        currency: currency,
        qrController: qrController,
        cardController: cardController,
        cashController: cashController,
        manualController: manualController,
        autoTotal: autoTotal,
      );
    case 2:
      return buildShiftStep3(
        setState: setState,
        isDark: isDark,
        totalSteps: totalSteps,
        currency: currency,
        morningCashController: morningCashController,
        eveningCashController: eveningCashController,
        inkassController: inkassController,
        hasInkass: hasInkass,
        tomorrowCash: tomorrowCash,
        onHasInkassChanged: (v) => setState(() {
          onHasInkassChanged(v);
          if (!v) inkassController.text = '0';
        }),
      );
    case 3:
      return buildShiftStep4(
        isDark: isDark,
        totalSteps: totalSteps,
        currency: currency,
        desserts: desserts,
        manualWriteOffs: manualWriteOffs,
        selectedStaff: selectedStaff,
        qrController: qrController,
        cardController: cardController,
        cashController: cashController,
        morningCashController: morningCashController,
        eveningCashController: eveningCashController,
        inkassController: inkassController,
        hasInkass: hasInkass,
        finalTotal: finalTotal,
        tomorrowCash: tomorrowCash,
        onSubmit: onSubmit,
      );
    default:
      return const SizedBox();
  }
}
