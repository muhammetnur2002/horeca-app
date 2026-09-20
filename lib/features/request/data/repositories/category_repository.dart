import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

class Category {
  final String id;
  final String name;
  final String departmentId;
  Category({required this.id, required this.name, required this.departmentId});
}

// Провайдер категорий, отфильтрованных по отделу
final categoriesProvider = Provider.family<List<Category>, String>((ref, departmentId) {
  final allCategories = ref.watch(settingsRepositoryProvider).categories;
  return allCategories
      .where((c) => c.departmentId == departmentId)
      .map((c) => Category(id: c.id, name: c.name, departmentId: c.departmentId))
      .toList();
});
