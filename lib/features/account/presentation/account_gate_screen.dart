import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/account/presentation/account_gate_widgets.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/notifications/data/notification_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Экран входа/регистрации по email. Показывается один раз при первом
/// запуске (или после выхода из аккаунта), прежде чем открыть основное
/// приложение. Есть возможность продолжить без аккаунта — на случай,
/// если у пользователя нет интернета или он не хочет облачную синхронизацию:
/// тогда приложение работает как раньше, полностью локально.
class AccountGateScreen extends ConsumerStatefulWidget {
  final VoidCallback onSkip;
  const AccountGateScreen({super.key, required this.onSkip});

  @override
  ConsumerState<AccountGateScreen> createState() => _AccountGateScreenState();
}

class _AccountGateScreenState extends ConsumerState<AccountGateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isRegisterMode = true;
  bool _isSyncing = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegisterMode && !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Подтвердите согласие с условиями, чтобы продолжить'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final notifier = ref.read(accountRepositoryProvider.notifier);
    final wasRegister = _isRegisterMode;
    final ok = _isRegisterMode
        ? await notifier.register(_emailCtrl.text, _passwordCtrl.text)
        : await notifier.login(_emailCtrl.text, _passwordCtrl.text);
    if (!ok || !mounted) return;

    if (wasRegister) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Письмо для подтверждения отправлено на ${_emailCtrl.text.trim()}'),
        behavior: SnackBarBehavior.floating,
      ));
    }

    final uid = ref.read(accountRepositoryProvider).uid;
    if (uid == null) return;

    setState(() => _isSyncing = true);
    final prefs = ref.read(sharedPreferencesProvider);
    final venueRepo = ref.read(venueRepositoryProvider.notifier);

    // Сверяем реестр заведений с облаком: если там есть заведения, которых
    // нет на этом устройстве — добавляем их в список (данные подтянутся,
    // когда на них реально зайдут по PIN). Затем отправляем актуальный
    // список обратно, чтобы у аккаунта в облаке он тоже был полным.
    final cloudVenues = await CloudSyncService.pullVenueRegistry(uid);
    if (cloudVenues != null) {
      venueRepo.mergeFromCloud(cloudVenues);
    }
    await CloudSyncService.pushVenueRegistry(uid, ref.read(venueRepositoryProvider).venues);

    final activeCode = ref.read(venueRepositoryProvider).activeVenueCode;
    final hasCloudData = await CloudSyncService.hasCloudData(uid, activeCode);
    if (hasCloudData) {
      await CloudSyncService.pullToLocal(uid, prefs, activeCode);
    } else {
      await CloudSyncService.pushToCloud(uid, prefs, activeCode);
    }
    // Репозитории уже могли закэшировать старые данные в памяти —
    // сбрасываем их, чтобы они перечитали SharedPreferences заново.
    ref.invalidate(settingsRepositoryProvider);
    ref.invalidate(historyRepositoryProvider);
    ref.invalidate(analyticsRepositoryProvider);
    ref.invalidate(notificationRepositoryProvider);
    if (mounted) setState(() => _isSyncing = false);
  }

  void _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Сначала введите email'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await ref
        .read(accountRepositoryProvider.notifier)
        .resetPassword(_emailCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Письмо для сброса пароля отправлено на ${_emailCtrl.text.trim()}'
          : 'Не удалось отправить письмо'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final accountState = ref.watch(accountRepositoryProvider);
    final isBusy = accountState.isLoading || _isSyncing;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.cloud_outlined,
                        color: AppColors.orange, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isRegisterMode
                        ? 'Создать аккаунт бизнеса'
                        : 'Вход в аккаунт',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Данные заведения будут доступны с любого устройства',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 32),

                  Text('EMAIL',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  GlassField(
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите email';
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Некорректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Text('ПАРОЛЬ',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  GlassField(
                    controller: _passwordCtrl,
                    hint: '••••••••',
                    isDark: isDark,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите пароль';
                      if (v.length < 6) return 'Минимум 6 символов';
                      // Требования по сложности применяем только при
                      // регистрации нового пароля — у существующих
                      // пользователей пароли могли быть заведены раньше
                      // и слабее, им нельзя блокировать вход.
                      if (_isRegisterMode) {
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return 'Добавьте хотя бы 1 цифру';
                        }
                        if (!RegExp(r'[A-ZА-ЯЁ]').hasMatch(v)) {
                          return 'Добавьте хотя бы 1 заглавную букву';
                        }
                        if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\];/\\~`]''')
                            .hasMatch(v)) {
                          return 'Добавьте хотя бы 1 спецсимвол (!@#\$% и т.п.)';
                        }
                      }
                      return null;
                    },
                  ),
                  if (_isRegisterMode) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Минимум 6 символов: цифра, заглавная буква и спецсимвол',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],

                  if (!_isRegisterMode) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isBusy ? null : _forgotPassword,
                        child: const Text('Забыли пароль?',
                            style: TextStyle(
                                color: AppColors.orange, fontSize: 13)),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 24),

                  if (_isRegisterMode) ...[
                    TermsAgreementCheckbox(
                      value: _agreedToTerms,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _agreedToTerms = v),
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (accountState.error != null) ...[
                    const SizedBox(height: 4),
                    Text(accountState.error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isBusy || (_isRegisterMode && !_agreedToTerms)
                        ? null
                        : _submit,
                    child: isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            _isRegisterMode ? 'Зарегистрироваться' : 'Войти',
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(
                      _isRegisterMode
                          ? 'Уже есть аккаунт? Войти'
                          : 'Нет аккаунта? Зарегистрироваться',
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isBusy ? null : widget.onSkip,
                    child: Text(
                      'Продолжить без аккаунта',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
