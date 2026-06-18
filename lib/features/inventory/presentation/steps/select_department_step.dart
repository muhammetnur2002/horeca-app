import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/request/data/repositories/department_repository.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class SelectDepartmentStep extends ConsumerWidget {
  const SelectDepartmentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = ref.watch(settingsRepositoryProvider).categories;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
              : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)],
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: departments.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return _DeptCard(
              icon: Icons.all_inclusive,
              label: l10n.allDepartments,
              isDark: isDark,
              accentColor: AppColors.green,
              onTap: () {
                final allCategoryIds =
                    allCategories.map((c) => c.id).toList();
                ref
                    .read(inventoryStateProvider.notifier)
                    .selectDepartment('all', allCategoryIds);
              },
            );
          }
          final d = departments[index - 1];
          return _DeptCard(
            icon: d.icon,
            label: d.name,
            isDark: isDark,
            accentColor: AppColors.orange,
            onTap: () {
              final categoryIds = allCategories
                  .where((c) => c.departmentId == d.id)
                  .map((c) => c.id)
                  .toList();
              ref
                  .read(inventoryStateProvider.notifier)
                  .selectDepartment(d.id, categoryIds);
            },
          );
        },
      ),
    );
  }
}

class _DeptCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _DeptCard({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_DeptCard> createState() => _DeptCardState();
}

class _DeptCardState extends State<_DeptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.accentColor
                        .withOpacity(widget.isDark ? 0.15 : 0.1),
                    widget.accentColor
                        .withOpacity(widget.isDark ? 0.05 : 0.04),
                  ],
                ),
                border: Border.all(
                  color: widget.accentColor.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        widget.accentColor.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Иконка в контейнере
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.accentColor
                          .withOpacity(widget.isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
