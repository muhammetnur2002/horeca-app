import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_recovery_dialog.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/notifications/data/notification_repository.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _error;

  void _addDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    _tryLogin();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  /// Если заведение одно (обычный случай) — вводится просто PIN, как раньше.
  /// Если заведений несколько — первые 2 цифры это код заведения (например
  /// "02"), а следующие 4 — пароль администратора/сотрудника этого заведения.
  Future<void> _tryLogin() async {
    final currentPin = _pin;
    final venueState = ref.read(venueRepositoryProvider);

    if (!venueState.isMultiVenue) {
      if (currentPin.length < 4) return;
      final repo = ref.read(authRepositoryProvider.notifier);
      final role = await repo.checkPinReady(currentPin);
      if (!mounted || _pin != currentPin) return;
      if (role != null) {
        repo.login(role);
      } else if (repo.lockoutSecondsRemaining > 0) {
        setState(() {
          _error = 'Слишком много попыток. Подождите ${repo.lockoutSecondsRemaining} сек.';
          _pin = '';
        });
      } else if (currentPin.length >= 6) {
        setState(() {
          _error = 'Неверный PIN-код';
          _pin = '';
        });
      }
      return;
    }

    if (currentPin.length < 6) return;
    final code = currentPin.substring(0, 2);
    final password = currentPin.substring(2);
    final venueNotifier = ref.read(venueRepositoryProvider.notifier);
    final venue = venueNotifier.findByCode(code);
    if (venue == null) {
      setState(() {
        _error = 'Неизвестный код заведения';
        _pin = '';
      });
      return;
    }
    venueNotifier.setActiveVenue(code);
    final repo = ref.read(authRepositoryProvider.notifier);
    final role = await repo.checkPinReady(password);
    if (!mounted || _pin != currentPin) return;
    if (role != null) {
      // Если это заведение на этом устройстве ещё не открывали (данных нет
      // локально), а аккаунт залогинен в облако — подтягиваем его данные,
      // прежде чем показать приложение (иначе увидим пустые заготовки
      // вместо реальных отделов/истории этого заведения).
      final account = ref.read(accountRepositoryProvider);
      if (account.isLoggedIn && account.uid != null) {
        final prefs = ref.read(sharedPreferencesProvider);
        final hasLocalData =
            prefs.getString('settings_data${venueKeySuffix(code)}') != null;
        if (!hasLocalData) {
          await CloudSyncService.pullToLocal(account.uid!, prefs, code);
          ref.invalidate(settingsRepositoryProvider);
          ref.invalidate(historyRepositoryProvider);
          ref.invalidate(analyticsRepositoryProvider);
          ref.invalidate(notificationRepositoryProvider);
        }
      }
      repo.login(role);
    } else if (repo.lockoutSecondsRemaining > 0) {
      setState(() {
        _error = 'Слишком много попыток. Подождите ${repo.lockoutSecondsRemaining} сек.';
        _pin = '';
      });
    } else {
      setState(() {
        _error = 'Неверный пароль для «${venue.name}»';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final isMultiVenue = ref.watch(venueRepositoryProvider).isMultiVenue;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 60),
            Container(width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.orange, size: 32)),
            const SizedBox(height: 20),
            Text('Введите PIN-код', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            if (isMultiVenue) ...[
              const SizedBox(height: 6),
              Text('Код заведения (2 цифры) + пароль (4 цифры)',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14, height: 14,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: filled ? AppColors.orange : Colors.transparent,
                      border: Border.all(color: filled ? AppColors.orange : AppColors.muted.withOpacity(0.4))),
                );
              }),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
            const Spacer(),
            _NumPad(onDigit: _addDigit, onBackspace: _removeDigit, isDark: isDark),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => showForgotPinDialog(context, ref),
              child: Text('Забыли PIN-код?',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            const SizedBox(height: 18),
          ]),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool isDark;
  const _NumPad({required this.onDigit, required this.onBackspace, required this.isDark});

  // Ширина слота = кнопка (72) + отступы по бокам (8+8). Пустышка в углу
  // должна занимать ровно столько же места, иначе следующие за ней
  // кнопки съезжают в сторону — раньше пустышка была просто 72 без
  // отступов и весь нижний ряд (0 и ⌫) визуально "уезжал" влево
  // относительно колонок 1-9 сверху. Теперь каждый слот — Expanded
  // одинаковой ширины, это гарантирует ровную сетку в любом случае.
  static const double _btnSize = 72;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: _btnSize + 16, height: _btnSize);
            }
            final isBackspace = key == '⌫';
            return GestureDetector(
              onTap: () => isBackspace ? onBackspace() : onDigit(key),
              child: Container(
                width: _btnSize,
                height: _btnSize,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
                    border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
                child: Center(
                  child: isBackspace
                      ? Icon(Icons.backspace_outlined, color: isDark ? Colors.white70 : const Color(0xFF1A1A2E), size: 22)
                      : Text(key, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}
