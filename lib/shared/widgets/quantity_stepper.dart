import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

/// Единый виджет "количество товара": кнопки -/+ и значение по центру,
/// по которому можно нажать и ввести число вручную.
///
/// Используется и в "Заявке" (product_list_step.dart), и в
/// "Инвентаризации" (input_remaining_step.dart) — раньше они выглядели
/// и вели себя чуть по-разному (разный размер кнопок, наличие/отсутствие
/// подчёркивания и подсветки цифры, разный диалог ручного ввода), теперь
/// оба места используют этот виджет, чтобы стиль был одинаковым.
class QuantityStepper extends StatelessWidget {
  final double value;
  final String unit;
  final bool isDark;
  final String productName;
  final ValueChanged<double> onChanged;
  final double step;

  /// Разрешить дробные значения (нужно для инвентаризации — например,
  /// "2.5 кг"). В заявке количество всегда целое.
  final bool allowDecimal;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.productName,
    required this.onChanged,
    this.step = 1,
    this.allowDecimal = false,
  });

  String get _formatted =>
      value == value.truncateToDouble() ? value.toInt().toString() : value.toString();

  void _showManualInput(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: value == 0 ? '' : _formatted);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(productName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          decoration: InputDecoration(hintText: '0', suffixText: unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = ctrl.text.trim().replaceAll(',', '.');
              var parsed = double.tryParse(raw);
              if (parsed != null && !allowDecimal) parsed = parsed.roundToDouble();
              final result = parsed ?? value;
              onChanged(result < 0 ? 0 : result);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQty = value > 0;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _QtyBtn(
        icon: Icons.remove,
        isDark: isDark,
        onTap: () {
          if (value > 0) {
            final next = value - step;
            onChanged(next < 0 ? 0 : next);
          }
        },
      ),
      GestureDetector(
        onTap: () => _showManualInput(context),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              _formatted,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: hasQty ? AppColors.orange : textColor,
                decoration: TextDecoration.underline,
                decorationColor: hasQty ? AppColors.orange : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
      _QtyBtn(icon: Icons.add, isDark: isDark, onTap: () => onChanged(value + step)),
    ]);
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _QtyBtn({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        // 44×44 — минимальный комфортный тап-таргет для сотрудников, которые
        // нажимают эту кнопку десятки раз подряд при инвентаризации, часто
        // мокрыми/жирными руками или в перчатках.
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.3)),
          ),
          child: Icon(icon, size: 18, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        ),
      );
}
