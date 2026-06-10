import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/data/repositories/department_repository.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';

class DepartmentStep extends ConsumerWidget {
  const DepartmentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (departments.isEmpty) {
      return Center(
        child: Text(
          'Нет отделов. Добавьте в настройках.',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: departments.length,
      itemBuilder: (_, index) {
        final d = departments[index];
        return Card(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          child: InkWell(
            onTap: () => ref.read(requestStateProvider.notifier).selectDepartment(d.id),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(d.icon, size: 48, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                  d.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}