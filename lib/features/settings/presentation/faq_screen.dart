import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

const _faqItems = [
  _FaqItem(
    question: 'Как сделать заявку на закупку?',
    answer:
        'На главном экране нажмите «Сделать заявку», выберите отдел '
        '(кухня, бар, склад, зал), затем категорию и товары, укажите '
        'нужное количество. Готовую заявку можно скопировать, отправить '
        'или сохранить в PDF.',
  ),
  _FaqItem(
    question: 'Как провести инвентаризацию?',
    answer:
        'Откройте «Инвентаризация» на главном экране, выберите отдел и '
        'категорию, затем укажите фактический остаток по каждому товару. '
        'В конце сформируется отчёт со всеми расхождениями.',
  ),
  _FaqItem(
    question: 'Как закрыть смену?',
    answer:
        'На главном экране нажмите «Закрытие смены». Укажите выручку, '
        'списания и, если включено, десерты — приложение соберёт итоговый '
        'отчёт и предложит сохранить его в PDF.',
  ),
  _FaqItem(
    question: 'Почему в закрытии смены не отображаются десерты?',
    answer:
        'Десерты определяются не по названию категории, а по отдельному '
        'переключателю. Откройте Настройки → Категории, найдите или '
        'создайте нужную категорию и включите переключатель «Десерты» '
        'при её добавлении или редактировании.',
  ),
  _FaqItem(
    question: 'Как добавить или удалить сотрудника?',
    answer:
        'Настройки → Сотрудники → значок «+» внизу экрана добавляет '
        'нового сотрудника. Чтобы удалить — нажмите на иконку корзины '
        'рядом с именем сотрудника.',
  ),
  _FaqItem(
    question: 'Как работают PIN-коды?',
    answer:
        'PIN-код защищает вход в приложение на конкретном устройстве и '
        'никогда не отправляется в облако. Настроить его можно в разделе '
        'входа/аккаунта — отдельно для администратора и для сотрудников.',
  ),
  _FaqItem(
    question: 'Как добавить второе заведение?',
    answer:
        'В Настройках, на вкладке «Приложение», откройте «Заведения» и '
        'нажмите «Добавить заведение». Между заведениями можно '
        'переключаться в любой момент — данные каждого хранятся отдельно.',
  ),
  _FaqItem(
    question: 'Можно ли удалить заведение?',
    answer:
        'Да, в разделе «Заведения» — но только с подтверждением PIN-кодом '
        'администратора или паролем от аккаунта, чтобы случайно не '
        'потерять данные. Нельзя удалить последнее оставшееся заведение.',
  ),
  _FaqItem(
    question: 'Данные пропадут, если я выйду из аккаунта или удалю приложение?',
    answer:
        'Пока вы не нажали «Выйти» вручную, сессия сохраняется даже после '
        'закрытия приложения или очистки списка недавних. Если вы вошли '
        'в аккаунт, данные также синхронизируются в облако — рекомендуем '
        'дополнительно делать резервную копию перед удалением приложения.',
  ),
  _FaqItem(
    question: 'Чем отличается тёмная тема от «Авто»?',
    answer:
        '«Авто» подстраивается под системную тему телефона и меняется '
        'вместе с ней. «Тёмная» и «Светлая» — фиксированный режим, '
        'который не зависит от настроек устройства.',
  ),
  _FaqItem(
    question: 'Для чего нужна интеграция с iiko?',
    answer:
        'Раздел iiko на главном экране показывает остатки склада напрямую '
        'из вашей системы iiko, если она подключена — это удобно, чтобы '
        'сверяться с ней при заявках и инвентаризации.',
  ),
  _FaqItem(
    question: 'Требования к паролю при регистрации',
    answer:
        'Пароль должен содержать минимум 6 символов, включая хотя бы одну '
        'цифру, одну заглавную букву и один спецсимвол. Это требование '
        'действует только при регистрации — уже существующие пароли '
        'продолжают работать при входе.',
  ),
];

/// Экран частых вопросов — доступен из "О программе". Список статичный,
/// без внешних сервисов, поэтому работает офлайн и полностью бесплатно.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: Text('Частые вопросы',
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
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 30),
            itemCount: _faqItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _FaqCard(item: _faqItems[i], isDark: isDark),
          ),
        ),
      ]),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final _FaqItem item;
  final bool isDark;
  const _FaqCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: AppColors.orange,
            collapsedIconColor: AppColors.muted,
            title: Text(item.question,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.answer,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? Colors.white.withOpacity(0.75)
                          : const Color(0xFF4A4A6A))),
            ],
          ),
        ),
      ),
    );
  }
}
