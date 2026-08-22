/// Карточка выбора валюты на вкладке "Приложение".
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';

const kAppCurrencies = [
  {'symbol': '₸', 'name': 'Тенге', 'flag': '🇰🇿'},
  {'symbol': '₽', 'name': 'Рубль', 'flag': '🇷🇺'},
  {'symbol': '\$', 'name': 'Доллар', 'flag': '🇺🇸'},
  {'symbol': '€', 'name': 'Евро', 'flag': '🇪🇺'},
  {'symbol': 'м', 'name': 'Манат', 'flag': '🇹🇲'},
  {'symbol': 'с', 'name': 'Сом', 'flag': '🇰🇬'},
];

class AppCurrencyCard extends StatelessWidget {
  final String currency;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const AppCurrencyCard({
    super.key,
    required this.currency,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border:
                Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.attach_money_rounded,
                        color: AppColors.green, size: 20)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Валюта',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  Text('Текущая: $currency',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
              ]),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kAppCurrencies.map((c) {
                  final sym = c['symbol']!;
                  final selected = currency == sym;
                  return GestureDetector(
                    onTap: () => onSelect(sym),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: selected
                            ? AppColors.orange.withOpacity(0.15)
                            : Colors.white.withOpacity(isDark ? 0.05 : 0.5),
                        border: Border.all(
                          color: selected
                              ? AppColors.orange
                              : Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c['flag']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sym,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? AppColors.orange : textColor)),
                            Text(c['name']!,
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.orange),
                        ],
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
