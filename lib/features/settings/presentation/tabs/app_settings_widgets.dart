/// Мелкие переиспользуемые карточки вкладки "Приложение".
/// Вынесены из app_settings_tab.dart, чтобы build() экрана не превращался
/// в стену вложенных Container/Row/Column.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

/// Переключатель "Десерты на закрытии смены".
class DessertsToggleCard extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const DessertsToggleCard({
    super.key,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.icecream_outlined,
                color: AppColors.orange, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Десерты на закрытии смены',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(
                  value
                      ? 'Показываются шаги "витрина/склад/списания"'
                      : 'Скрыты — остались только смена и ручные списания',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.orange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Строка-ссылка "иконка / заголовок / подзаголовок" (лого, название,
/// заведения, о программе).
class AboutRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const AboutRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

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

/// Крупная карточка-ссылка с блюром (уведомления, свой шаблон PDF) —
/// раньше эти два блока дублировались в build() почти дословно, здесь —
/// один параметризуемый виджет.
class SettingsNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const SettingsNavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
              border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.4)),
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
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              )),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted.withOpacity(0.5)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Зелёная информационная плашка под блоком "Лого/название".
class SettingsInfoBanner extends StatelessWidget {
  final String text;
  final bool isDark;
  const SettingsInfoBanner({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.green.withOpacity(isDark ? 0.08 : 0.05),
            border: Border.all(color: AppColors.green.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.green))),
          ]),
        ),
      ),
    );
  }
}
