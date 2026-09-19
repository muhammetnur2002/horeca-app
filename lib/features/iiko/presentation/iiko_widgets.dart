/// Мелкие виджеты экрана iiko: карточки подключения (форма логина / статус
/// "подключено"), строки выбора организации/склада, строка остатка.
/// Вынесены из iiko_screen.dart, чтобы не раздувать его build().
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/iiko/data/iiko_service.dart';
import 'package:horeca_app/features/iiko/data/iiko_request_suggester.dart';

class LoginCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark, loading;
  final VoidCallback onConnect;
  const LoginCard({
    super.key,
    required this.controller,
    required this.isDark,
    required this.loading,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.store_rounded, color: AppColors.orange, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text('Подключить iiko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
            ]),
            const SizedBox(height: 8),
            Text('Введите API-логин из личного кабинета iikoWeb (раздел интеграции)',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'API-логин',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: const Icon(Icons.key_rounded, color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Подключить'),
            ),
          ]),
        ),
      ),
    );
  }
}

class ConnectedCard extends StatelessWidget {
  final String orgName;
  final bool isDark, loading;
  final VoidCallback onRefresh;
  const ConnectedCard({
    super.key,
    required this.orgName,
    required this.isDark,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.green.withOpacity(isDark ? 0.08 : 0.05),
            border: Border.all(color: AppColors.green.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text('Подключено: $orgName', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Загрузить остатки'),
            ),
          ]),
        ),
      ),
    );
  }
}

class SelectRow extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  const SelectRow({super.key, required this.title, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
        child: Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class CheckRow extends StatelessWidget {
  final String title;
  final bool isDark, checked;
  final ValueChanged<bool?> onChanged;
  const CheckRow({super.key, required this.title, required this.isDark, required this.checked, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: CheckboxListTile(
        value: checked,
        onChanged: onChanged,
        title: Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        activeColor: AppColors.orange,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

String _formatQty(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Диалог подтверждения перед созданием заявки из остатков iiko — сотрудник
/// видит, какие товары попали в подборку и сколько предлагается заказать,
/// прежде чем список уйдёт в обычный экран заявки на редактирование.
Future<bool> showLowStockRequestDialog(
  BuildContext context, {
  required bool isDark,
  required List<LowStockSuggestion> suggestions,
}) async {
  final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Заявка по остаткам iiko',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${suggestions.length} ${suggestions.length == 1 ? "товар" : "товара(ов)"} ниже минимального остатка:',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = suggestions[i];
                  return Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.product.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                          Text('Остаток: ${_formatQty(s.currentAmount)} ${s.iikoUnit}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Text('+${_formatQty(s.suggestedQuantity)} ${s.product.unit}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.orange)),
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена', style: TextStyle(color: AppColors.muted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Создать заявку'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class BalanceRow extends StatelessWidget {
  final IikoBalanceItem item;
  final bool isDark;
  const BalanceRow({super.key, required this.item, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: Row(children: [
        Expanded(child: Text(item.productName, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
        Text('${item.amount} ${item.unit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.orange)),
      ]),
    );
  }
}
