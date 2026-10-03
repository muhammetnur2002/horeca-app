import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/home/presentation/home_logo_title.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/onboarding/data/onboarding_repository.dart';
import 'package:horeca_app/features/onboarding/presentation/onboarding_overlay.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authRepositoryProvider);
    final isAdmin = authState.role != UserRole.staff;
    final pinsEnabled = ref.read(authRepositoryProvider.notifier).pinsEnabled;

    final onboardingSeen = ref.watch(onboardingRepositoryProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final stockLevels = ref.watch(stockLevelsRepositoryProvider);
    final lowStockItems = settings.products.where((p) {
      if (p.minStock == null) return false;
      final current = stockLevels[p.id];
      if (current == null) return false;
      return current < p.minStock!;
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AkylLogoTitle(isDark: isDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (pinsEnabled)
            IconButton(
              icon: Icon(Icons.lock_outline_rounded,
                  color: isDark ? Colors.white70 : AppColors.ink),
              tooltip: 'Заблокировать',
              // Возвращает на экран ввода PIN, не закрывая приложение —
              // например, чтобы передать телефон другому сотруднику или
              // сменить заведение. До этой кнопки выйти из PIN-сессии можно
              // было только полностью закрыв приложение.
              onPressed: () =>
                  ref.read(authRepositoryProvider.notifier).logout(),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _Background(isDark: isDark)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Кнопок стало больше — на маленьких экранах список
              // прокручивается, а не обрезается.
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _GreetingHeader(isDark: isDark, userName: authState.userName),
                    const SizedBox(height: 16),
                    if (lowStockItems.isNotEmpty) ...[
                      _LowStockBanner(items: lowStockItems, isDark: isDark),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 4),
                    _GlassButton(
                      icon: Icons.assignment_outlined,
                      label: l10n.makeRequest,
                      sublabel: 'Кухня, бар, склад, зал',
                      isPrimary: true,
                      isDark: isDark,
                      onTap: () => context.push('/request'),
                    ),
                    const SizedBox(height: 12),
                    _GlassButton(
                      icon: Icons.nights_stay_outlined,
                      label: 'Закрытие смены',
                      sublabel: 'Отчёт и PDF',
                      isPrimary: false,
                      isDark: isDark,
                      accentColor: AppColors.green,
                      onTap: () => context.push('/shift-close'),
                    ),
                    const SizedBox(height: 12),
                    _GlassButton(
                      icon: Icons.inventory_2_outlined,
                      label: l10n.inventory,
                      sublabel: 'Подсчёт остатков',
                      isPrimary: false,
                      isDark: isDark,
                      onTap: () => context.push('/inventory'),
                    ),
                    const SizedBox(height: 12),
                    _GlassButton(
                      icon: Icons.local_shipping_outlined,
                      label: 'Учёт товара',
                      sublabel: 'Приёмка поставки, остатки, расход',
                      isPrimary: false,
                      isDark: isDark,
                      accentColor: AppColors.accent3,
                      onTap: () => context.push('/stock'),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      _GlassButton(
                        icon: Icons.insights_rounded,
                        label: 'Аналитика и инсайты',
                        sublabel: 'Графики, тренды, списания',
                        isPrimary: false,
                        isDark: isDark,
                        accentColor: const Color(0xFF9966FF),
                        onTap: () => context.push('/analytics'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _GlassButton(
                      icon: Icons.store_rounded,
                      label: 'iiko',
                      sublabel: 'Остатки на складе',
                      isPrimary: false,
                      isDark: isDark,
                      accentColor: const Color(0xFF378ADD),
                      onTap: () => context.push('/iiko'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!onboardingSeen)
            OnboardingOverlay(
              onFinish: () =>
                  ref.read(onboardingRepositoryProvider.notifier).markSeen(),
            ),
        ],
      ),
    );
  }
}

// ── Фон ─────────────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final bool isDark;
  const _Background({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: BackdropGradient(isDark),
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  final List<dynamic> items;
  final bool isDark;
  const _LowStockBanner({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.08),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 18)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                '${items.length} ${items.length == 1 ? "товар заканчивается" : "товара заканчиваются"}: ${items.map((p) => p.name).take(2).join(", ")}${items.length > 2 ? "..." : ""}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.85)
                        : AppColors.ink))),
      ]),
    );
  }
}

// ── Приветствие ──────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final bool isDark;

  /// Имя сотрудника, вошедшего по личному PIN.
  final String? userName;
  const _GreetingHeader({required this.isDark, this.userName});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.ink;
    final subColor = isDark ? AppColors.muted : const Color(0xFF6B7280);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(userName == null ? _greeting() : '${_greeting()}, $userName',
          style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.3)),
      const SizedBox(height: 4),
      Text(_formattedDate(), style: TextStyle(fontSize: 14, color: subColor)),
    ]);
  }
}

// ── Кнопка ───────────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isPrimary;
  final bool isDark;
  final Color? accentColor;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.orange;
    // Один яркий градиент на экран — у главного действия; остальные
    // кнопки — матовое стекло поверх туманностей.
    final onPrimary = isPrimary;
    final titleColor =
        onPrimary ? Colors.white : (isDark ? Colors.white : AppColors.ink);
    final subColor = onPrimary
        ? Colors.white.withOpacity(0.8)
        : (isDark ? Colors.white.withOpacity(0.55) : AppColors.inkSoft);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [AppColors.orange, AppColors.green]
                  : [
                      Colors.white.withOpacity(isDark ? 0.09 : 0.62),
                      Colors.white.withOpacity(isDark ? 0.04 : 0.38)
                    ],
            ),
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withOpacity(0.25)
                  : Colors.white.withOpacity(isDark ? 0.12 : 0.85),
            ),
          ),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withOpacity(0.2)
                        : accent.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon,
                    color: isPrimary ? Colors.white : accent, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: TextStyle(fontSize: 13, color: subColor)),
                ])),
            Icon(Icons.chevron_right_rounded,
                color: isPrimary
                    ? Colors.white.withOpacity(0.8)
                    : isDark
                        ? Colors.white.withOpacity(0.25)
                        : Colors.black.withOpacity(0.2),
                size: 20),
          ]),
        ),
        ),
      ),
    );
  }
}
