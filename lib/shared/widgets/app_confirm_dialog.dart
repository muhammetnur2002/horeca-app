import 'package:flutter/material.dart';
import 'package:horeca_app/app/design/tokens.dart';

/// Спрашивает подтверждение перед необратимым действием.
///
/// В приложении набралось 25 самодельных диалогов, и все они спрашивали
/// по-разному: где-то «Отмена / OK», где-то «Нет / Да», кнопка удаления
/// то красная, то оранжевая. Человек, который каждый день закрывает смену,
/// перестаёт читать такие окна и жмёт по памяти — а память подводит, когда
/// кнопки меняются местами.
///
/// Здесь порядок один: отказ слева, действие справа, и его подпись
/// называет само действие («Удалить», «Очистить»), а не «OK». Опасное
/// действие красится в [AppPalette.danger].
///
/// Возвращает true, только если человек подтвердил.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Подтвердить',
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final palette = dialogContext.palette;
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: palette.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              minimumSize: const Size(88, kMinTapTarget),
              foregroundColor: palette.textSecondary,
            ),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, kMinTapTarget),
              backgroundColor:
                  destructive ? palette.danger : palette.action,
              foregroundColor:
                  destructive ? Colors.white : palette.onAction,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
