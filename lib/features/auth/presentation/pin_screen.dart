import 'package:flutter/material.dart';
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

  void _addDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length >= 4) {
      _tryLogin();
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _tryLogin() {
    final repo = ref.read(authRepositoryProvider.notifier);
    final role = repo.checkPin(_pin);
    if (role != null) {
      repo.login(role);
    } else if (_pin.length >= 6) {
      setState(() {
        _error = 'Неверный PIN-код';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

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
  const _NumPad({required this.onDigit, required this.onBackspace, required this.isDark});

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
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 72, height: 72);
            final isBackspace = key == '⌫';
            return GestureDetector(
              onTap: () => isBackspace ? onBackspace() : onDigit(key),
              child: Container(
                width: 72, height: 72,
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