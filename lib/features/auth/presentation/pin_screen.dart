import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_recovery_dialog.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _shake() => _shakeCtrl.forward(from: 0);

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
      if (repo.lockoutSecondsRemaining > 0) {
        _showLockout(repo.lockoutSecondsRemaining);
        return;
      }
      // Верный код из 4 или 5 цифр открывает сразу. Ошибка считается
      // один раз, только когда набраны все 6 цифр и совпадения нет.
      final role = await repo.peekPinReady(currentPin);
      if (!mounted || _pin != currentPin) return;
      if (role != null) {
        repo.checkPin(currentPin);
        repo.login(role);
        return;
      }
      if (currentPin.length >= 6) {
        repo.checkPin(currentPin);
        if (repo.lockoutSecondsRemaining > 0) {
          _showLockout(repo.lockoutSecondsRemaining);
        } else {
          setState(() {
            _error = 'Неверный PIN. Осталось попыток: ${repo.attemptsRemaining}';
            _pin = '';
          });
          _shake();
        }
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
          ref.read(cloudAutoSyncProvider).reloadMirrors();
        }
      }
      repo.login(role);
    } else if (repo.lockoutSecondsRemaining > 0) {
      _showLockout(repo.lockoutSecondsRemaining);
    } else {
      setState(() {
        _error =
            'Неверный пароль для «${venue.name}». Осталось попыток: ${repo.attemptsRemaining}';
        _pin = '';
      });
      _shake();
    }
  }

  void _showLockout(int seconds) {
    setState(() {
      _error = 'Слишком много попыток. Подождите $seconds сек.';
      _pin = '';
    });
    _shake();
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
            const SizedBox(height: 6),
            Text(
              isMultiVenue
                  ? 'Сначала 2 цифры кода заведения, потом 4 цифры пароля'
                  : 'От 4 до 6 цифр. Верный код откроется сразу',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 30),
            AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) {
                final t = _shakeCtrl.value;
                final dx = sin(t * pi * 6) * (1 - t) * 12;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: filled ? 16 : 14,
                    height: filled ? 16 : 14,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: filled ? AppColors.orange : Colors.transparent,
                        border: Border.all(color: filled ? AppColors.orange : AppColors.muted.withOpacity(0.4)),
                        boxShadow: filled
                            ? [BoxShadow(color: AppColors.orange.withOpacity(0.45), blurRadius: 10)]
                            : null),
                  );
                }),
              ),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
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
