/// Восстановление доступа с экрана ввода PIN, если код забыт или введён в
/// неправильном формате. Раньше такого пути не было вообще: неверный
/// PIN-код означал, что человек застревал на этом экране без единого
/// способа вернуться в приложение (кроме полной очистки данных телефона).
/// Вынесено из pin_screen.dart, чтобы не раздувать его.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

Future<void> showForgotPinDialog(BuildContext context, WidgetRef ref) async {
  final account = ref.read(accountRepositoryProvider);

  // Без облачного аккаунта на этом устройстве подтвердить личность
  // удалённо нечем — единственный честный вариант это сказать об этом
  // прямо, а не притворяться, что восстановление возможно.
  if (!account.isLoggedIn) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Забыли PIN-код?'),
        content: const Text(
          'Это устройство не привязано к облачному аккаунту, поэтому '
          'подтвердить личность удалённо нельзя. Если у вас есть аккаунт, '
          'но сейчас нет интернета — попробуйте снова, когда сеть '
          'появится. Иначе единственный способ сбросить PIN — очистить '
          'данные приложения в настройках телефона (это также удалит '
          'все данные, которые не сохранены в облаке).',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно')),
        ],
      ),
    );
    return;
  }

  final l10n = AppLocalizations.of(context);
  final venueState = ref.read(venueRepositoryProvider);
  String? selectedCode = venueState.isMultiVenue ? null : '01';
  final pwCtrl = TextEditingController();
  bool obscure = true;
  bool isChecking = false;
  String? error;

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Восстановление доступа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Введите пароль от аккаунта${account.email != null ? ' (${account.email})' : ''} '
              '— это подтвердит, что телефон ваш, и снимет PIN-защиту для '
              'заведения. Новый PIN можно будет задать заново в Настройках.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (venueState.isMultiVenue) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedCode,
                items: venueState.venues
                    .map((v) => DropdownMenuItem(
                        value: v.code, child: Text('${v.code} — ${v.name}')))
                    .toList(),
                onChanged: (v) => setState(() => selectedCode = v),
                decoration: const InputDecoration(labelText: 'Заведение'),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: pwCtrl,
              obscureText: obscure,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Пароль аккаунта',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.orange),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.muted, size: 20),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: isChecking ? null : () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: isChecking || selectedCode == null
                ? null
                : () async {
                    final password = pwCtrl.text;
                    if (password.isEmpty) return;
                    setState(() {
                      isChecking = true;
                      error = null;
                    });
                    final ok = await ref
                        .read(accountRepositoryProvider.notifier)
                        .verifyPassword(password);
                    if (!ok) {
                      setState(() {
                        isChecking = false;
                        error = 'Неверный пароль';
                      });
                      return;
                    }
                    final code = selectedCode!;
                    final prefs = ref.read(sharedPreferencesProvider);
                    await AuthRepository.clearPinsForVenue(prefs, code);
                    ref.read(venueRepositoryProvider.notifier).setActiveVenue(code);
                    // Раз личность уже подтверждена паролем аккаунта — сразу
                    // пускаем внутрь администратором, а не возвращаем на
                    // теперь-уже-отключённый экран PIN.
                    ref.read(authRepositoryProvider.notifier).login(UserRole.admin);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Сбросить PIN и войти'),
          ),
        ],
      ),
    ),
  );
}
