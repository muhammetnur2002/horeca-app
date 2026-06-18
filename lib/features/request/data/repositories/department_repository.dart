import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

class Department {
  final String id;
  final String name;
  final IconData icon;
  Department({required this.id, required this.name, required this.icon});
}

// Теперь этот провайдер зависит от настроек и автоматически обновляется
final departmentsProvider = Provider<List<Department>>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return settings.departments
      .map((d) => Department(id: d.id, name: d.name, icon: d.icon))
      .toList();
});
