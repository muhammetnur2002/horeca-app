/// Мелкие виджеты экрана входа/регистрации: чекбокс согласия с
/// юридическими документами и стеклянное текстовое поле. Вынесены из
/// account_gate_screen.dart, чтобы не раздувать его build().
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/presentation/legal_documents.dart';

/// Обязательный чекбокс согласия с юридическими документами при
/// регистрации нового аккаунта. Показывается только в режиме регистрации —
/// у уже существующих пользователей согласие подразумевается при первом
/// входе и повторно не запрашивается.
class TermsAgreementCheckbox extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const TermsAgreementCheckbox({
    super.key,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF4A4A6A);
    final linkStyle = const TextStyle(
        color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600);
    final plainStyle = TextStyle(color: textColor, fontSize: 12);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.orange,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Wrap(
              children: [
                Text('Я согласен с ', style: plainStyle),
                GestureDetector(
                  onTap: () => showTermsOfUse(context),
                  child: Text('Условиями использования', style: linkStyle),
                ),
                Text(', ', style: plainStyle),
                GestureDetector(
                  onTap: () => showPrivacyPolicy(context),
                  child: Text('Политикой конфиденциальности', style: linkStyle),
                ),
                Text(' и ', style: plainStyle),
                GestureDetector(
                  onTap: () => showUserAgreement(context),
                  child: Text('Пользовательским соглашением', style: linkStyle),
                ),
                Text('.', style: plainStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const GlassField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
                fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
