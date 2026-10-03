/// Диалог «Личный PIN и роль» сотрудника на вкладке персонала.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/auth/data/staff_pin_service.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Сотрудники заведения из базы (с ролью и признаком личного PIN).
/// Перечитывается при изменении списка сотрудников в настройках.
final staffRowsProvider = FutureProvider<List<StaffMemberRow>>((ref) async {
  ref.watch(settingsRepositoryProvider.select((s) => s.staff));
  await ref.read(settingsRepositoryProvider.notifier).pendingStaffWrite;
  return ref.watch(staffPinServiceProvider).loadStaff();
});

Future<void> showStaffPinDialog(
  BuildContext context,
  WidgetRef ref,
  StaffMemberRow staff,
) {
  return showDialog(
    context: context,
    builder: (_) => _StaffPinDialog(staff: staff),
  );
}

class _StaffPinDialog extends ConsumerStatefulWidget {
  final StaffMemberRow staff;
  const _StaffPinDialog({required this.staff});

  @override
  ConsumerState<_StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends ConsumerState<_StaffPinDialog> {
  late String _role = widget.staff.role;
  final _pinCtrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  String? _error;
  bool _busy = false;

  bool get _hasPin => widget.staff.pinHash != null;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(staffPinServiceProvider);
    final pin = _pinCtrl.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    if (pin.isEmpty && _hasPin) {
      // PIN не меняем — только роль.
      await service.setRole(widget.staff.id, _role);
    } else if (pin != _pin2Ctrl.text.trim()) {
      error = 'PIN-коды не совпадают';
    } else {
      final code = ref.read(venueRepositoryProvider).activeVenueCode;
      error = await service.setPin(
        staffId: widget.staff.id,
        pin: pin,
        role: _role,
        sharedPins: [
          await AuthRepository.readAdminPinForVenue(code),
          await AuthRepository.readStaffPinForVenue(code),
        ],
      );
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    ref.invalidate(staffRowsProvider);
    Navigator.pop(context);
  }

  Future<void> _clear() async {
    await ref
        .read(staffPinServiceProvider)
        .clearPin(widget.staff.id, role: _role);
    if (!mounted) return;
    ref.invalidate(staffRowsProvider);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final code = ref.watch(venueRepositoryProvider).activeVenueCode;
    final pinsEnabled = AuthRepository.pinsEnabledForVenue(
        ref.read(sharedPreferencesProvider), code);

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          counterText: '',
          labelStyle: TextStyle(color: AppColors.muted),
        );

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.staff.fullName,
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Личный PIN подписывает приёмку, инвентаризацию и закрытие '
              'смены именем сотрудника. Общие PIN заведения продолжают '
              'работать.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (!pinsEnabled) ...[
              const SizedBox(height: 10),
              Text(
                'Вход по PIN сейчас выключен — включите его в '
                'Настройки → Заведения, чтобы личный PIN спрашивался при входе.',
                style: TextStyle(fontSize: 12.5, color: AppColors.orange),
              ),
            ],
            const SizedBox(height: 16),
            Text('Роль',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final (value, label) in [
                ('staff', 'Сотрудник'),
                ('admin', 'Администратор'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _role == value,
                  selectedColor: AppColors.orange.withOpacity(0.2),
                  onSelected: (_) => setState(() => _role = value),
                ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: deco(_hasPin
                  ? 'Новый PIN (пусто — оставить прежний)'
                  : 'Личный PIN (4 цифры)'),
            ),
            TextField(
              controller: _pin2Ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: deco('Повторите PIN'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
          ],
        ),
      ),
      actions: [
        if (_hasPin)
          TextButton(
            onPressed: _busy ? null : _clear,
            child: const Text('Убрать PIN',
                style: TextStyle(color: Colors.redAccent)),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text('Отмена', style: TextStyle(color: AppColors.muted)),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
