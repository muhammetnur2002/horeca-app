import 'package:flutter/material.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/people/domain/people_calc.dart';
import 'package:horeca_app/features/people/domain/people_models.dart';

const peopleMonths = <String>[
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
  'декабря',
];

String formatRuDate(DateTime date) {
  final day = dateOnly(date);
  return '${day.day} ${peopleMonths[day.month - 1]} ${day.year}';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} КБ';
  final megabytes = bytes / (1024 * 1024);
  final text = megabytes >= 10 ? megabytes.toStringAsFixed(0) : megabytes.toStringAsFixed(1);
  return '$text МБ';
}

Color experienceColor(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.little:
      return const Color(0xFFE24B4B);
    case ExperienceLevel.medium:
      return const Color(0xFFE0A100);
    case ExperienceLevel.much:
      return const Color(0xFF639922);
  }
}

class PeopleColors {
  final bool isDark;
  const PeopleColors(this.isDark);

  Color get text => isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get sub => isDark ? AppColors.muted : const Color(0xFF6B7280);
  Color get card => isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.78);
  Color get cardBorder => isDark ? Colors.white.withOpacity(0.10) : Colors.white;
  Color get field => isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F8FC);
  Color get sheet => isDark ? AppColors.darkCard : Colors.white;
}

class PeopleBackground extends StatelessWidget {
  final bool isDark;
  const PeopleBackground({required this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
              : const [Color(0xFFEEF2FF), Color(0xFFF7F8FF), Color(0xFFFFF4EC)],
        ),
      ),
    );
  }
}

class PeopleCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const PeopleCard({
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(isDark);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? colors.cardBorder),
      ),
      child: child,
    );
  }
}

class PeopleSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;

  const PeopleSectionHeader({
    required this.title,
    required this.isDark,
    this.action,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PeopleColors(isDark);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.text),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

void showPeopleMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> askPeopleConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = PeopleColors(isDark);
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colors.sheet,
      title: Text(title, style: TextStyle(color: colors.text)),
      content: Text(body, style: TextStyle(color: colors.sub, height: 1.35)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(confirm)),
      ],
    ),
  );
  return answer == true;
}

Future<T?> showPeopleSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = PeopleColors(isDark);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
          ),
          decoration: BoxDecoration(
            color: colors.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: builder(sheetContext),
          ),
        ),
      );
    },
  );
}

InputDecoration peopleField(PeopleColors colors, String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: colors.field,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}
