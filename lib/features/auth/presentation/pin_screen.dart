import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});
  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _error;
  Timer? _lockTicker;

  @override
  void dispose() {
    _lockTicker?.cancel();
    super.dispose();
  }

  /// Пока действует блокировка — раз в секунду обновляем обратный отсчёт.
  void _ensureLockTicker() {
    if (_lockTicker != null) return;
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final locked = ref.read(authRepositoryProvider).isLocked;
      setState(() {});
      if (!locked) {
        t.cancel();
        _lockTicker = null;
      }
    });
  }

  void _addDigit(String digit) {
    if (ref.read(authRepositoryProvider).isLocked) return;
    final maxLen = ref.read(authRepositoryProvider.notifier).pinMaxLength;
    if (_pin.length >= maxLen) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length >= 4) _tryLogin();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _tryLogin() {
    final repo = ref.read(authRepositoryProvider.notifier);
    if (ref.read(authRepositoryProvider).isLocked) return;

    final role = repo.checkPin(_pin);
    if (role != null) {
      HapticFeedback.lightImpact();
      repo.login(role);
      return;
    }

    // Подбор длины: PIN может быть от 4 до pinMaxLength цифр, поэтому
    // неудачей считаем только полностью введённый код.
    if (_pin.length < repo.pinMaxLength) return;

    repo.registerFailure();
    HapticFeedback.heavyImpact();
    final st = ref.read(authRepositoryProvider);
    if (st.isLocked) _ensureLockTicker();
    setState(() {
      _pin = '';
      _error = st.isLocked
          ? null
          : 'Неверный PIN-код. Осталось попыток: '
              '${AuthRepository.maxAttempts - (st.failedAttempts % AuthRepository.maxAttempts)}';
    });
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '$m мин ${s.toString().padLeft(2, '0')} с';
    return '$s с';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final auth = ref.watch(authRepositoryProvider);
    final maxLen = ref.read(authRepositoryProvider.notifier).pinMaxLength;
    final locked = auth.isLocked;
    if (locked) _ensureLockTicker();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                    : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 60),
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: (locked ? Colors.redAccent : AppColors.orange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(
                    locked ? Icons.lock_clock_rounded : Icons.lock_outline_rounded,
                    color: locked ? Colors.redAccent : AppColors.orange,
                    size: 32)),
            const SizedBox(height: 20),
            Text(locked ? 'Вход заблокирован' : 'Введите PIN-код',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 30),
            if (locked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Слишком много неверных попыток.\n'
                  'Повторите через ${_formatRemaining(auth.lockRemaining)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, height: 1.5),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(maxLen, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.orange : Colors.transparent,
                        border: Border.all(
                            color: filled
                                ? AppColors.orange
                                : AppColors.muted.withValues(alpha: 0.4))),
                  );
                }),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            const Spacer(),
            Opacity(
              opacity: locked ? 0.35 : 1,
              child: IgnorePointer(
                ignoring: locked,
                child: _NumPad(
                    onDigit: _addDigit, onBackspace: _removeDigit, isDark: isDark),
              ),
            ),
            const SizedBox(height: 30),
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
  const _NumPad(
      {required this.onDigit, required this.onBackspace, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'backspace'],
    ];
    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((key) {
                    if (key.isEmpty) return const SizedBox(width: 72, height: 72);
                    final isBackspace = key == 'backspace';
                    return Semantics(
                      button: true,
                      label: isBackspace ? 'Удалить цифру' : 'Цифра $key',
                      child: GestureDetector(
                        onTap: () => isBackspace ? onBackspace() : onDigit(key),
                        child: Container(
                          width: 72,
                          height: 72,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(alpha: isDark ? 0.06 : 0.6),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: isDark ? 0.1 : 0.4))),
                          child: Center(
                            child: isBackspace
                                ? Icon(Icons.backspace_outlined,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF1A1A2E),
                                    size: 22)
                                : Text(key,
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E))),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ))
          .toList(),
    );
  }
}
