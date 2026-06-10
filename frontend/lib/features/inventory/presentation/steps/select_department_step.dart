import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/data/repositories/department_repository.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';

class SelectDepartmentStep extends ConsumerWidget {
  const SelectDepartmentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: departments.length + 1, // +1 для "Все отделы"
      itemBuilder: (_, index) {
        if (index == 0) {
          // Карточка "Все отделы"
          return Card(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            child: InkWell(
              onTap: () => ref.read(inventoryStateProvider.notifier).selectDepartment('all'),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.all_inclusive, size: 48, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    'Все отделы',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                ],
              ),
            ),
          );
        }
        final d = departments[index - 1];
        return Card(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          child: InkWell(
            onTap: () => ref.read(inventoryStateProvider.notifier).selectDepartment(d.id),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}