import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/history/data/history_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_settings_screen.dart';

class ThemeTab extends ConsumerWidget {
  const ThemeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final isDark = themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 130, 20, 20),
      child: Column(
        children: [
          // Карточка с иконкой
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    // живая иконка логотипа
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _AkylIcon(key: ValueKey(themeMode), isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.translate('theme') ?? 'Тема',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      themeMode == ThemeMode.system
                          ? 'Системная тема'
                          : isDark
                              ? 'Тёмная тема включена'
                              : 'Светлая тема включена',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Кнопки выбора темы
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(ThemeMode.light),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: themeMode == ThemeMode.light
                          ? AppColors.orange.withOpacity(0.12)
                          : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                      border: Border.all(
                        color: themeMode == ThemeMode.light
                            ? AppColors.orange.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                        width: themeMode == ThemeMode.light ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            color: themeMode == ThemeMode.light
                                ? AppColors.orange
                                : AppColors.muted,
                            size: 28),
                        const SizedBox(height: 8),
                        Text('Светлая',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: themeMode == ThemeMode.light
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: themeMode == ThemeMode.light
                                  ? AppColors.orange
                                  : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(ThemeMode.system),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: themeMode == ThemeMode.system
                          ? AppColors.green.withOpacity(0.12)
                          : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                      border: Border.all(
                        color: themeMode == ThemeMode.system
                            ? AppColors.green.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                        width: themeMode == ThemeMode.system ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.brightness_auto_rounded,
                            color: themeMode == ThemeMode.system
                                ? AppColors.green
                                : AppColors.muted,
                            size: 28),
                        const SizedBox(height: 8),
                        Text('Авто',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: themeMode == ThemeMode.system
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: themeMode == ThemeMode.system
                                  ? AppColors.green
                                  : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: themeMode == ThemeMode.dark
                          ? AppColors.orange.withOpacity(0.12)
                          : Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                      border: Border.all(
                        color: themeMode == ThemeMode.dark
                            ? AppColors.orange.withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                        width: themeMode == ThemeMode.dark ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.nightlight_round,
                            color: themeMode == ThemeMode.dark
                                ? AppColors.orange
                                : AppColors.muted,
                            size: 28),
                        const SizedBox(height: 8),
                        Text('Тёмная',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: themeMode == ThemeMode.dark
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: themeMode == ThemeMode.dark
                                  ? AppColors.orange
                                  : AppColors.muted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── О программе ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text('О ПРОГРАММЕ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.muted, letterSpacing: 0.6)),
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
            onTap: () => _showPrivacyPolicy(context, isDark),
          ),
          const SizedBox(height: 10),
          _AboutRow(
            icon: Icons.description_outlined,
            title: 'Условия использования',
            subtitle: 'Правила и ограничения ответственности',
            color: AppColors.orange,
            isDark: isDark,
            onTap: () => _showTermsOfUse(context, isDark),
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
const SizedBox(height: 10),
_AboutRow(
  icon: Icons.admin_panel_settings_outlined,
  title: 'Управление доступом',
  subtitle: 'PIN-коды для администратора и сотрудников',
  color: const Color(0xFF378ADD),
  isDark: isDark,
  onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => const PinSettingsScreen())),
),

const SizedBox(height: 20),
Text('Akyl v1.0.0 — управляй с умом',
    style: TextStyle(fontSize: 11, color: AppColors.muted.withOpacity(0.6))),
      ],
    ),
  );
}
  

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Связаться с нами', style: TextStyle(fontWeight: FontWeight.w600)),
          content: const Text(
              'Напишите нам на почту:\nsupport@akylapp.com\n\nМы отвечаем в течение 1-2 рабочих дней.',
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Закрыть', style: TextStyle(color: AppColors.muted))),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Политика конфиденциальности',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Text(
  'ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ\n'
  'Приложение Akyl\n'
  'Дата последнего обновления: 21 июня 2026 года\n\n'

  '1. ОБЩИЕ ПОЛОЖЕНИЯ\n'
  'Akyl — мобильное приложение для управления заведениями общественного '
  'питания (кафе, рестораны). Приложение работает в офлайн-режиме: все '
  'данные, которые вы вводите, хранятся локально на вашем устройстве.\n\n'

  '2. КАКИЕ ДАННЫЕ МЫ ОБРАБАТЫВАЕМ\n'
  'Мы не собираем, не храним на серверах и не передаём третьим лицам '
  'никакие пользовательские данные. Вся информация — название заведения, '
  'товары, отделы, сотрудники, заявки, инвентаризации, отчёты о закрытии '
  'смены — хранится исключительно на вашем устройстве в локальном '
  'хранилище приложения.\n\n'
  'Если вы используете функцию подключения к стороннему сервису (например, '
  'iiko), данные передаются непосредственно между вашим устройством и '
  'сервером этого сервиса по протоколу HTTPS. Akyl не выступает '
  'посредником и не сохраняет эти данные.\n\n'

  '3. РАЗРЕШЕНИЯ ПРИЛОЖЕНИЯ\n'
  'Akyl может запрашивать следующие разрешения:\n'
  '— доступ к фото/галерее — для добавления логотипа заведения;\n'
  '— доступ к файлам — для создания и сохранения резервных копий, '
  'а также для импорта файла резервной копии;\n'
  '— уведомления — для напоминаний о заказе товаров и инвентаризации.\n'
  'Эти разрешения используются только локально и не передают данные '
  'на сервер.\n\n'

  '4. РЕЗЕРВНОЕ КОПИРОВАНИЕ\n'
  'Функция создания резервной копии формирует файл на вашем устройстве. '
  'Вы самостоятельно решаете, где сохранить этот файл (облако, почта, '
  'мессенджер). Akyl не имеет доступа к этому файлу после его создания.\n\n'

  '5. АНАЛИТИКА И СТАТИСТИКА\n'
  'Приложение не использует сторонние аналитические SDK, рекламные сети '
  'или системы сбора статистики использования. Графики и отчёты, '
  'отображаемые в разделе «Аналитика», рассчитываются локально на основе '
  'данных, введённых вами.\n\n'

  '6. ПЛАТНЫЕ ФУНКЦИИ\n'
  'На момент публикации приложение Akyl является полностью бесплатным. '
  'В будущем разработчик может ввести платную подписку на отдельные '
  'расширенные функции. В этом случае условия оплаты, состав платных '
  'функций и порядок возврата средств будут описаны дополнительно и '
  'размещены в актуальной версии настоящей политики до момента введения '
  'платных функций. Обработка платежей в этом случае будет осуществляться '
  'через официальные платёжные инструменты магазина приложений (RuStore, '
  'Google Play и др.), которые имеют собственные политики конфиденциальности.\n\n'

  '7. ДЕТИ\n'
  'Приложение не предназначено для детей младше 16 лет и не собирает '
  'данные несовершеннолетних.\n\n'

  '8. ИЗМЕНЕНИЯ ПОЛИТИКИ\n'
  'Мы можем обновлять данную политику. Актуальная версия всегда доступна '
  'в приложении в разделе Настройки.\n\n'

  '9. КОНТАКТЫ\n'
  'По вопросам обработки данных пишите на support@akylapp.com',
  style: TextStyle(fontSize: 14, height: 1.6,
      color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E)),
),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsOfUse(BuildContext context, bool isDark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Условия использования',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Text(
  'УСЛОВИЯ ИСПОЛЬЗОВАНИЯ\n'
  'Приложение Akyl\n'
  'Дата последнего обновления: 21 июня 2026 года\n\n'

  '1. ПРИНЯТИЕ УСЛОВИЙ\n'
  'Используя приложение Akyl, вы подтверждаете своё согласие с настоящими '
  'условиями. Если вы не согласны — пожалуйста, не используйте приложение.\n\n'

  '2. НАЗНАЧЕНИЕ ПРИЛОЖЕНИЯ\n'
  'Akyl предназначен для учёта заявок на товары, инвентаризации и '
  'закрытия смен в кафе и ресторанах. Приложение не является '
  'бухгалтерским, фискальным или юридически значимым документооборотом '
  'и не заменяет кассовое оборудование, требуемое законодательством.\n\n'

  '3. ТОЧНОСТЬ ДАННЫХ\n'
  'Все расчёты выполняются на основе данных, введённых пользователем. '
  'Разработчик не несёт ответственности за ошибки, убытки или '
  'расхождения, возникшие из-за неверно введённой информации.\n\n'

  '4. ХРАНЕНИЕ И СОХРАННОСТЬ ДАННЫХ\n'
  'Все данные хранятся локально на устройстве пользователя. Разработчик '
  'не несёт ответственности за потерю данных при удалении приложения, '
  'сбросе настроек, поломке устройства или иных действиях пользователя. '
  'Рекомендуется регулярно создавать резервные копии через функцию '
  '«Создать бэкап» в настройках.\n\n'

  '5. ИНТЕЛЛЕКТУАЛЬНАЯ СОБСТВЕННОСТЬ\n'
  'Логотип, название «Akyl», дизайн интерфейса и код приложения являются '
  'собственностью разработчика. Копирование, распространение или '
  'модификация приложения без письменного разрешения запрещены.\n\n'

  '6. ОГРАНИЧЕНИЕ ОТВЕТСТВЕННОСТИ\n'
  'Приложение предоставляется «как есть» (as is), без каких-либо гарантий. '
  'Разработчик не гарантирует бесперебойную и безошибочную работу '
  'приложения и не несёт ответственности за прямые или косвенные убытки, '
  'связанные с использованием или невозможностью использования '
  'приложения.\n\n'

  '7. ПЛАТНЫЕ ФУНКЦИИ И ПОДПИСКА\n'
  'На текущий момент приложение предоставляется бесплатно. В случае '
  'введения платной подписки на расширенные функции в будущем, условия '
  'оплаты, продления, отмены подписки и возврата средств будут '
  'регулироваться правилами соответствующего магазина приложений '
  '(RuStore, Google Play и др.), через который осуществляется покупка. '
  'Отмена подписки выполняется через настройки соответствующего магазина '
  'приложений.\n\n'

  '8. СТОРОННИЕ СЕРВИСЫ\n'
  'При использовании функции интеграции со сторонними сервисами '
  '(например, iiko) применяются условия использования и политики этих '
  'сервисов. Разработчик Akyl не несёт ответственности за работу '
  'сторонних сервисов.\n\n'

  '9. ИЗМЕНЕНИЕ УСЛОВИЙ\n'
  'Разработчик может обновлять данные условия. Продолжение использования '
  'приложения после публикации обновлённых условий означает согласие '
  'с ними.\n\n'

  '10. ПРИМЕНИМОЕ ПРАВО\n'
  'Настоящие условия регулируются законодательством Российской '
  'Федерации в части, применимой к пользователям из РФ.\n\n'

  '11. КОНТАКТЫ\n'
  'По всем вопросам — support@akylapp.com',
  style: TextStyle(fontSize: 14, height: 1.6,
      color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E)),
),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showThirdPartyLicenses(BuildContext context, bool isDark) async {
  final text = await DefaultAssetBundle.of(context)
      .loadString('assets/licenses/third_party_licenses.txt');
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Лицензии открытого ПО',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Text(text,
                    style: TextStyle(fontSize: 12, height: 1.5, fontFamily: 'monospace',
                        color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1A1A2E))),
              ),
            ),
          ],
        ),
      ),
    ),
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
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена', style: TextStyle(color: AppColors.muted))),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
  const _AboutRow({required this.icon, required this.title, required this.subtitle,
      required this.color, required this.isDark, required this.onTap});

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
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: AppColors.muted.withOpacity(0.5)),
        ]),
      ),
    );
  }
}

// ── Живая анимированная иконка ────────────────────────────────────────────

// ── Живая анимированная иконка ────────────────────────────────────────────
class _AkylIcon extends StatefulWidget {
  final bool isDark;
  const _AkylIcon({super.key, required this.isDark});

  @override
  State<_AkylIcon> createState() => _AkylIconState();
}

class _AkylIconState extends State<_AkylIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: const Size(100, 100),
        painter: _IconPainter(
          t: _ctrl.value * 8,
          isDark: widget.isDark,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final double t;
  final bool isDark;
  const _IconPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final CX = W / 2, CY = H / 2;

    // фон иконки
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, W, H), const Radius.circular(22));
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.2,
          colors: isDark
              ? [const Color(0xFF1A1E2E), const Color(0xFF0D1128), const Color(0xFF060A18)]
              : [const Color(0xFFEEF2FF), const Color(0xFFDDE8FF), const Color(0xFFC8D8FF)],
        ).createShader(Rect.fromLTWH(0, 0, W, H)),
    );

    // орбиты
    final orbitPaint = Paint()
      ..color = (isDark ? const Color(0xFF8C5020) : const Color(0xFFB05A10))
          .withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final rot in [-0.52, 0.52]) {
      canvas.save();
      canvas.translate(CX, CY);
      canvas.rotate(rot);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: W * 0.82, height: H * 0.25),
          orbitPaint);
      canvas.restore();
    }

    // планеты
    for (int i = 0; i < 2; i++) {
      final rot = i == 0 ? -0.52 : 0.52;
      final ang = i == 0 ? t * 0.75 - 1.57 : -t * 0.6 + 3.14;
      final r = i == 0 ? 5.5 : 4.5;
      final px = cos(ang) * W * 0.41;
      final py = sin(ang) * H * 0.125;
      final wx = CX + px * cos(rot) - py * sin(rot);
      final wy = CY + px * sin(rot) + py * cos(rot);
      canvas.drawCircle(
        Offset(wx, wy),
        r,
        Paint()
          ..shader = RadialGradient(colors: const [
            Color(0xFFFFB067),
            Color(0xFFF5862E),
          ]).createShader(
              Rect.fromCircle(center: Offset(wx, wy), radius: r)),
      );
    }

    // буква A
    final tp = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          fontSize: W * 0.48,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas,
        Offset(CX - tp.width / 2, CY - tp.height / 2 + W * 0.02));
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.t != t || old.isDark != isDark;
}




