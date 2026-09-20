import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/notifications/data/notification_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final data = ref.watch(notificationRepositoryProvider);
    final repo = ref.read(notificationRepositoryProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Настройка уведомлений',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Инвентаризация
              Text('ИНВЕНТАРИЗАЦИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.muted, letterSpacing: 0.6)),
              const SizedBox(height: 10),
              _InventoryReminderCard(reminder: data.inventoryReminder, isDark: isDark,
                  onChanged: (r) => repo.setInventoryReminder(r)),

              const SizedBox(height: 24),

              // Напоминания о товарах
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('НАПОМИНАНИЯ О ЗАКАЗЕ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.muted, letterSpacing: 0.6)),
                GestureDetector(
                  onTap: () => _showAddReminderDialog(context, ref, isDark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.orange.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(l10n.add, style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              if (data.productReminders.isEmpty)
                Text('Нет настроенных напоминаний', style: TextStyle(fontSize: 13, color: AppColors.muted))
              else
                ...data.productReminders.map((r) => _ReminderRow(
                  reminder: r, isDark: isDark,
                  onDelete: () => repo.removeProductReminder(r.id),
                )),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    ReminderFrequency frequency = ReminderFrequency.daily;
    int weekday = 1;
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
    final weekdayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Напоминание о товаре', style: TextStyle(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Название товара',
                    prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.orange))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setS(() => frequency = ReminderFrequency.daily),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      color: frequency == ReminderFrequency.daily ? AppColors.orange.withOpacity(0.15) : Colors.transparent,
                      border: Border.all(color: frequency == ReminderFrequency.daily ? AppColors.orange : AppColors.muted.withOpacity(0.3))),
                    child: const Text('Каждый день', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.orange))))),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => setS(() => frequency = ReminderFrequency.weekly),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      color: frequency == ReminderFrequency.weekly ? AppColors.green.withOpacity(0.15) : Colors.transparent,
                      border: Border.all(color: frequency == ReminderFrequency.weekly ? AppColors.green : AppColors.muted.withOpacity(0.3))),
                    child: const Text('Раз в неделю', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.green))))),
              ]),
              if (frequency == ReminderFrequency.weekly) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 6, children: List.generate(7, (i) {
                  final wd = i + 1;
                  final sel = weekday == wd;
                  return GestureDetector(
                    onTap: () => setS(() => weekday = wd),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: sel ? AppColors.green : Colors.transparent,
                          border: Border.all(color: sel ? AppColors.green : AppColors.muted.withOpacity(0.3))),
                      child: Center(child: Text(weekdayNames[i],
                          style: TextStyle(fontSize: 11, color: sel ? Colors.white : AppColors.muted))),
                    ),
                  );
                })),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: time);
                  if (picked != null) setS(() => time = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.muted.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text('Время: ${time.format(ctx)}', style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted))),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  await ref.read(notificationRepositoryProvider.notifier).addProductReminder(
                    productName: nameCtrl.text.trim(),
                    frequency: frequency,
                    hour: time.hour,
                    minute: time.minute,
                    weekday: frequency == ReminderFrequency.weekly ? weekday : null,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.add)),
          ],
        ),
      ),
    );
  }
}

class _InventoryReminderCard extends StatelessWidget {
  final InventoryReminder reminder;
  final bool isDark;
  final ValueChanged<InventoryReminder> onChanged;
  const _InventoryReminderCard({required this.reminder, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Напоминать об инвентаризации', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              Switch(value: reminder.enabled, activeColor: AppColors.orange,
                  onChanged: (v) => onChanged(reminder.copyWith(enabled: v))),
            ]),
            if (reminder.enabled) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final day = await showDialog<int>(
                      context: context,
                      builder: (ctx) => _DayPickerDialog(initial: reminder.dayOfMonth, isDark: isDark),
                    );
                    if (day != null) onChanged(reminder.copyWith(dayOfMonth: day));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.muted.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.orange),
                      const SizedBox(width: 8),
                      Text('День: ${reminder.dayOfMonth}', style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(context: context,
                        initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute));
                    if (picked != null) onChanged(reminder.copyWith(hour: picked.hour, minute: picked.minute));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.muted.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.orange),
                      const SizedBox(width: 8),
                      Text('${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Checkbox(value: reminder.dayBeforeEnabled, activeColor: AppColors.orange,
                    onChanged: (v) => onChanged(reminder.copyWith(dayBeforeEnabled: v))),
                Expanded(child: Text('Предупредить за день', style: TextStyle(fontSize: 13, color: textColor))),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _DayPickerDialog extends StatelessWidget {
  final int initial;
  final bool isDark;
  const _DayPickerDialog({required this.initial, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Выберите день месяца'),
      content: SizedBox(
        width: 300, height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: 28,
          itemBuilder: (ctx, i) {
            final day = i + 1;
            return GestureDetector(
              onTap: () => Navigator.pop(context, day),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: day == initial ? AppColors.orange : Colors.transparent),
                child: Center(child: Text('$day',
                    style: TextStyle(color: day == initial ? Colors.white : null))),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final ProductReminder reminder;
  final bool isDark;
  final VoidCallback onDelete;
  const _ReminderRow({required this.reminder, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final weekdayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final freqText = reminder.frequency == ReminderFrequency.daily
        ? 'Каждый день'
        : 'Каждый ${weekdayNames[(reminder.weekday ?? 1) - 1]}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active_outlined, color: AppColors.orange, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reminder.productName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          Text('$freqText в ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: onDelete),
      ]),
    );
  }
}
