import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/settings/presentation/faq_screen.dart';
import 'package:horeca_app/features/settings/presentation/legal_documents.dart';
import 'package:horeca_app/features/onboarding/data/onboarding_repository.dart';

/// Отдельный экран "О программе": сюда убрали чисто информационные пункты
/// (поддержка, политика конфиденциальности, условия использования, сброс
/// данных), чтобы вкладка "Тема и управление" не была перегружена текстом
/// и оставалась про настройку внешнего вида и заведений.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('О программе',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Stack(children: [
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                            : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 30),
            children: [
              _AboutRow(
                icon: Icons.help_outline_rounded,
                title: 'Частые вопросы',
                subtitle: 'Ответы на популярные вопросы',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const FaqScreen())),
              ),
              const SizedBox(height: 10),
              _AboutRow(
                icon: Icons.school_outlined,
                title: 'Показать обучение заново',
                subtitle: 'Короткий тур по основным экранам',
                color: const Color(0xFF9966FF),
                isDark: isDark,
                onTap: () => _replayOnboarding(context, ref),
              ),
              const SizedBox(height: 10),
              _AboutRow(
                icon: Icons.support_agent_rounded,
                title: 'Связаться с нами',
                subtitle: 'Вопросы, ошибки, предложения',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () => _contactSupport(context),
              ),
              const SizedBox(height: 10),
              _AboutRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Политика конфиденциальности',
                subtitle: 'Как мы обращаемся с вашими данными',
                color: AppColors.green,
                isDark: isDark,
                onTap: () => showPrivacyPolicy(context),
              ),
              const SizedBox(height: 10),
              _AboutRow(
                icon: Icons.description_outlined,
                title: 'Условия использования',
                subtitle: 'Правила и ограничения ответственности',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () => showTermsOfUse(context),
              ),
              const SizedBox(height: 10),
              _AboutRow(
                icon: Icons.gavel_rounded,
                title: 'Пользовательское соглашение',
                subtitle: 'Оферта — ответственность за аккаунт и данные',
                color: AppColors.green,
                isDark: isDark,
                onTap: () => showUserAgreement(context),
              ),
              const SizedBox(height: 10),
              _AboutRow(
                icon: Icons.delete_forever_outlined,
                title: 'Очистить все данные',
                subtitle: 'Сбросить настройки и удалить всё',
                color: Colors.redAccent,
                isDark: isDark,
                onTap: () => _confirmResetAll(context, ref, isDark),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('Akyl v1.0.0 — управляй с умом',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.muted.withOpacity(0.6))),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // Сбрасывает флаг "тур пройден" и возвращает пользователя на главный
  // экран, где OnboardingOverlay снова покажется поверх содержимого —
  // сначала закрываем все экраны, открытые поверх (сама "О программе",
  // FAQ и т.д.), и только потом переключаем вкладку через go_router.
  void _replayOnboarding(BuildContext context, WidgetRef ref) {
    ref.read(onboardingRepositoryProvider.notifier).resetForReplay();
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    navigator.popUntil((route) => route.isFirst);
    router.go('/');
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Связаться с нами',
              style: TextStyle(fontWeight: FontWeight.w600)),
          content: const Text(
              'Напишите нам на почту:\nsupport@akylapp.com\n\nМы отвечаем в течение 1-2 рабочих дней.',
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Закрыть',
                    style: TextStyle(color: AppColors.muted))),
          ],
        );
      },
    );
  }

  void _confirmResetAll(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Очистить все данные?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text(
            'Будут удалены все настройки, товары, сотрудники и история. '
            'Это действие нельзя отменить.',
            style: TextStyle(color: AppColors.muted, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена',
                  style: TextStyle(color: AppColors.muted))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(settingsRepositoryProvider.notifier).resetAll();
                ref.read(historyRepositoryProvider).clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Все данные очищены'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Удалить всё')),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  const _AboutRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border:
              Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
        ),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted)),
              ])),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.muted.withOpacity(0.5)),
        ]),
      ),
    );
  }
}
