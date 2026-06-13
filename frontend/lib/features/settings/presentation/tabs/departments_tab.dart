import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/widgets/animated_list_item.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class DepartmentsTab extends ConsumerWidget {
  const DepartmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final departments = ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, repo, l10n),
        child: const Icon(Icons.add),
      ),
      body: departments.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade500),
                  const SizedBox(height: 16),
                  Text(l10n.noDepartments, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: departments.length,
              itemBuilder: (_, index) {
                final dept = departments[index];
                return AnimatedListItem(
                  child: Card(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    child: ListTile(
                      leading: Icon(dept.icon, color: Colors.orange),
                      title: Text(dept.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)), // <-- реальное имя
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, repo, dept, l10n),
                      ),
                      onTap: () => _showEditDialog(context, repo, dept, l10n),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo, DepartmentModel dept, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirm),
        content: Text('${l.deleteConfirm} «${dept.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              repo.deleteDepartment(dept.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.successDepartmentDeleted} «${dept.name}»')),
              );
            },
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, SettingsRepository repo, AppLocalizations l) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addDepartment),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                repo.addDepartment(nameCtrl.text, Icons.category);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l.successDepartmentAdded} «${nameCtrl.text}»')),
                );
              }
            },
            child: Text(l.add),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, SettingsRepository repo, DepartmentModel dept, AppLocalizations l) {
    final nameCtrl = TextEditingController(text: dept.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editDepartment),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Название')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                repo.updateDepartment(dept.id, nameCtrl.text, null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l.successDepartmentUpdated} «${nameCtrl.text}»')),
                );
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}