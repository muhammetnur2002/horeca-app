/// Диалог добавления ручного списания на шаге 1 закрытия смены. Вынесен из
/// shift_close_step1_shift.dart, чтобы не раздувать его.
library;

import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';

void showAddManualWriteOffDialog({
  required BuildContext context,
  required bool isDark,
  required StateSetter setState,
  required List<ManualWriteOff> manualWriteOffs,
}) {
  final nameCtrl = TextEditingController();
  String selectedUnit = 'шт';
  final units = ['шт', 'кг', 'гр', 'л', 'мл'];
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Ручное списание',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                        hintText: 'Продукт, заготовка...',
                        prefixIcon:
                            Icon(Icons.edit_outlined, color: AppColors.orange))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                  items: units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedUnit = v!),
                  decoration: const InputDecoration(
                      labelText: 'Единица измерения',
                      prefixIcon: Icon(Icons.straighten_rounded,
                          color: AppColors.orange)),
                ),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена',
                        style: TextStyle(color: AppColors.muted))),
                ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        setState(() => manualWriteOffs.add(ManualWriteOff(
                            name: nameCtrl.text.trim(), unit: selectedUnit)));
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Добавить')),
              ],
            )),
  );
}
