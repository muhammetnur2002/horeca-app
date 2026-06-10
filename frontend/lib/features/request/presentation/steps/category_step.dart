import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/request/data/repositories/category_repository.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';

class CategoryStep extends ConsumerWidget {
  const CategoryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestStateProvider);
    if (state.departmentId == null) {
      return const Center(child: Text('Сначала выберите отдел'));
    }
    final categories = ref.watch(categoriesProvider(state.departmentId!));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Нет категорий. Добавьте в настройках.',
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
      itemCount: categories.length,
      itemBuilder: (_, index) {
        final c = categories[index];
        return Card(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          child: InkWell(
            onTap: () => ref.read(requestStateProvider.notifier).selectCategory(c.id),
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                c.name,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}