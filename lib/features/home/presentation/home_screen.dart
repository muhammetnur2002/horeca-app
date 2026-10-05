import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/core/money.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/onboarding/data/onboarding_repository.dart';
import 'package:horeca_app/features/onboarding/presentation/onboarding_overlay.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/widgets/spiral_mark.dart';

/// «Позже» в подсказке Akyl — скрывает её до перезапуска приложения.
final _hintDismissedProvider = StateProvider<bool>((_) => false);

/// Главный экран по макету «Орбита»: шапка с заведением, подсказка
/// «Akyl думает», крупная кнопка заявки и плитки разделов с живыми цифрами.
/// Разделы и переходы — прежние.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authRepositoryProvider);
    final isAdmin = authState.role != UserRole.staff;
    final pinsEnabled = ref.read(authRepositoryProvider.notifier).pinsEnabled;
    final venue = ref.watch(venueRepositoryProvider).active;

    final onboardingSeen = ref.watch(onboardingRepositoryProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final stockLevels = ref.watch(stockLevelsRepositoryProvider);
    final shifts = ref.watch(analyticsRepositoryProvider);
    final lowStockItems = settings.products.where((p) {
      if (p.minStock == null) return false;
      final current = stockLevels[p.id];
      if (current == null) return false;
      return current < p.minStock!;
    }).toList();

    final lastShift = shifts.isEmpty
        ? null
        : (List<ShiftRecord>.from(shifts)
              ..sort((a, b) => b.date.compareTo(a.date)))
            .first;
    final revenueChange =
        ref.read(analyticsRepositoryProvider.notifier).getRevenueChangePercent();

    final tiles = <_TileData>[
      _TileData(
        icon: Icons.nights_stay_outlined,
        title: 'Смена',
        sub: lastShift == null
            ? 'отчёт и PDF'
            : '${formatMoney(lastShift.revenue)} ${settings.currency}',
        // В моноширинном шрифте нет знака валюты — сумма текстовым
        // шрифтом с цифрами одинаковой ширины.
        mono: lastShift == null,
        color: AppColors.green,
        route: '/shift-close',
      ),
      _TileData(
        icon: Icons.inventory_2_outlined,
        title: l10n.inventory,
        sub: lowStockItems.isEmpty
            ? 'подсчёт остатков'
            : '${lowStockItems.length} на исходе',
        subColor: lowStockItems.isEmpty ? null : AppColors.accent3,
        color: AppColors.orange,
        route: '/inventory',
      ),
      _TileData(
        icon: Icons.local_shipping_outlined,
        title: 'Учёт товара',
        sub: 'приёмка · расход',
        color: AppColors.accent3,
        route: '/stock',
      ),
      if (isAdmin)
        _TileData(
          icon: Icons.insights_rounded,
          title: 'Аналитика',
          sub: revenueChange == null
              ? 'графики, тренды'
              : '${revenueChange >= 0 ? '+' : ''}${revenueChange.round()}% к смене',
          subColor: revenueChange == null
              ? null
              : (revenueChange >= 0 ? AppColors.green : Colors.redAccent),
          color: AppColors.orangeLight,
          route: '/analytics',
        ),
      _TileData(
        icon: Icons.store_rounded,
        title: 'iiko',
        sub: 'остатки склада',
        color: AppColors.greenLight,
        route: '/iiko',
      ),
    ];

    return Scaffold(
      // Под экраном — фон оболочки (тот же), поэтому без своего цвета.
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: BackdropGradient(isDark)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    venueLabel: venue == null
                        ? null
                        : '${venue.code} · ${venue.name}',
                    showLock: pinsEnabled,
                    onLock: () =>
                        ref.read(authRepositoryProvider.notifier).logout(),
                  ),
                  const SizedBox(height: 18),
                  _Greeting(isDark: isDark, userName: authState.userName),
                  const SizedBox(height: 16),
                  _AkylHint(
                    isDark: isDark,
                    lowStock: lowStockItems,
                    levels: stockLevels,
                    hasProducts: settings.products.isNotEmpty,
                    hasLevels: stockLevels.isNotEmpty,
                    isAdmin: isAdmin,
                  ),
                  _RequestCard(
                    title: l10n.makeRequest,
                    subtitle: lowStockItems.isEmpty
                        ? 'Кухня, бар, склад, зал'
                        : '${lowStockItems.length} ${_positions(lowStockItems.length)} '
                            '${lowStockItems.length % 10 == 1 && lowStockItems.length % 100 != 11 ? 'просит' : 'просят'} пополнения',
                    onTap: () => context.push('/request'),
                  ),
                  const SizedBox(height: 12),
                  _TileGrid(tiles: tiles, isDark: isDark),
                ],
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

  static String _positions(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'позиция';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'позиции';
    return 'позиций';
  }
}

// ── Шапка ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String? venueLabel;
  final bool showLock;
  final VoidCallback onLock;

  const _TopBar({
    required this.venueLabel,
    required this.showLock,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white70 : AppColors.inkSoft;
    return Row(children: [
      SpiralMark(size: 40, isDark: isDark),
      const Spacer(),
      if (venueLabel != null)
        _GlassPill(
          child: Text(venueLabel!,
              style: TextStyle(fontSize: 12, color: fg)),
        ),
      if (showLock) ...[
        const SizedBox(width: 8),
        _GlassPill(
          onTap: onLock,
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.lock_outline_rounded, size: 16, color: fg),
        ),
      ],
    ]);
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const _GlassPill({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(isDark ? 0.07 : 0.6),
          border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.14 : 0.9)),
        ),
        child: child,
      ),
    );
  }
}

// ── Приветствие ────────────────────────────────────────────────────────────
class _Greeting extends StatelessWidget {
  final bool isDark;

  /// Имя сотрудника, вошедшего по личному PIN.
  final String? userName;
  const _Greeting({required this.isDark, this.userName});

  static const _days = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля',
    'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final textColor = isDark ? Colors.white : AppColors.ink;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '${_days[now.weekday - 1]} · ${now.day} ${_months[now.month - 1]} · '
        '${two(now.hour)}:${two(now.minute)}',
        style: TextStyle(
            fontFamily: AppFonts.mono, fontSize: 11.5, color: AppColors.muted),
      ),
      const SizedBox(height: 6),
      Text(
        userName == null ? _greeting(now) : '${_greeting(now)}, $userName',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.3,
        ),
      ),
    ]);
  }
}

// ── «Akyl думает» ──────────────────────────────────────────────────────────
class _AkylHint extends ConsumerWidget {
  final bool isDark;
  final List<ProductModel> lowStock;
  final Map<String, double> levels;
  final bool hasProducts;
  final bool hasLevels;
  final bool isAdmin;

  const _AkylHint({
    required this.isDark,
    required this.lowStock,
    required this.levels,
    required this.hasProducts,
    required this.hasLevels,
    required this.isAdmin,
  });

  String _q(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(_hintDismissedProvider)) return const SizedBox.shrink();

    // Подсказка — одна, самая полезная сейчас.
    final String text;
    final String action;
    final String route;
    if (lowStock.isNotEmpty) {
      final p = lowStock.first;
      text = lowStock.length == 1
          ? '${p.name} заканчивается — осталось ${_q(levels[p.id] ?? 0)} '
              '${p.inventoryUnit}. Добавить в заявку?'
          : '${lowStock.length} товара на исходе: '
              '${lowStock.take(2).map((p) => p.name).join(', ')}'
              '${lowStock.length > 2 ? '…' : ''}. Собрать заявку?';
      action = 'В заявку';
      route = '/request';
    } else if (!hasProducts) {
      if (!isAdmin) return const SizedBox.shrink();
      text = 'Добавьте товары или загрузите их из iiko — '
          'и я начну подсказывать, что заказать.';
      action = 'Настроить';
      route = '/settings';
    } else if (!hasLevels) {
      text = 'Проведите инвентаризацию — буду предупреждать, '
          'когда товар заканчивается.';
      action = 'Начать';
      route = '/inventory';
    } else {
      return const SizedBox.shrink();
    }

    final textColor = isDark ? Colors.white : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(isDark ? 0.07 : 0.62),
              border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.12 : 0.9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const _PulseDot(),
                  const SizedBox(width: 8),
                  Text('AKYL ДУМАЕТ',
                      style: TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 10.5,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green)),
                ]),
                const SizedBox(height: 8),
                Text(text,
                    style:
                        TextStyle(fontSize: 14, height: 1.35, color: textColor)),
                const SizedBox(height: 12),
                Row(children: [
                  _HintButton(
                    label: action,
                    primary: true,
                    onTap: () => context.push(route),
                  ),
                  const SizedBox(width: 8),
                  _HintButton(
                    label: 'Позже',
                    primary: false,
                    onTap: () =>
                        ref.read(_hintDismissedProvider.notifier).state = true,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HintButton(
      {required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: primary
              ? AppColors.orange
              : Colors.white.withOpacity(isDark ? 0.08 : 0.8),
          border: primary
              ? null
              : Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 1)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.ink))),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Container(
            width: 6 + 6 * _c.value,
            height: 6 + 6 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withOpacity(0.5 * (1 - _c.value)),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
          ),
        ]),
      ),
    );
  }
}

// ── Крупная кнопка заявки ──────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RequestCard(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orange, AppColors.greenLight],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkBg.withOpacity(0.85),
            ),
            child: const Icon(Icons.north_east_rounded,
                color: Colors.white, size: 20),
          ),
        ]),
      ),
    );
  }
}

// ── Плитки разделов ────────────────────────────────────────────────────────
class _TileData {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final Color? subColor;
  final String route;
  final bool mono;

  const _TileData({
    this.mono = true,
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.route,
    this.subColor,
  });
}

class _TileGrid extends StatelessWidget {
  final List<_TileData> tiles;
  final bool isDark;
  const _TileGrid({required this.tiles, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final pair = tiles.skip(i).take(2).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _Tile(data: pair[0], isDark: isDark)),
            if (pair.length == 2) ...[
              const SizedBox(width: 12),
              Expanded(child: _Tile(data: pair[1], isDark: isDark)),
            ],
          ]),
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _Tile extends StatelessWidget {
  final _TileData data;
  final bool isDark;
  const _Tile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(data.route),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(isDark ? 0.07 : 0.6),
              border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.12 : 0.9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(isDark ? 0.2 : 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(data.icon, color: data.color, size: 19),
                ),
                const SizedBox(height: 18),
                Text(data.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.ink)),
                const SizedBox(height: 4),
                Text(data.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: data.mono ? AppFonts.mono : null,
                        fontFamilyFallback: AppFonts.fallback,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: data.mono ? 11 : 12.5,
                        fontWeight: data.mono ? null : FontWeight.w600,
                        color: data.subColor ?? AppColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
