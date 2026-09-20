/// Импорт товаров из номенклатуры iiko в каталог Akyl — часть незавершённой
/// задачи "Импорт товаров из iiko" (см. описание.docx). У iiko нет понятия
/// "отдел" (это внутреннее деление Akyl для заявок), поэтому сотрудник сам
/// выбирает отдел-получатель, а группы iiko становятся категориями внутри
/// него. Импорт только добавляет данные — уже существующие категории/товары
/// с таким же названием не дублируются (см. isDuplicateProduct).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/iiko/data/iiko_service.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_products.dart';
import 'package:horeca_app/features/settings/data/settings_repository_staff.dart';
import 'package:horeca_app/shared/models/department_model.dart';

class IikoImportScreen extends ConsumerStatefulWidget {
  final String token;
  final String organizationId;
  const IikoImportScreen(
      {super.key, required this.token, required this.organizationId});

  @override
  ConsumerState<IikoImportScreen> createState() => _IikoImportScreenState();
}

class _IikoImportScreenState extends ConsumerState<IikoImportScreen> {
  final _service = IikoService();
  bool _loading = true;
  String? _error;
  IikoNomenclature? _nomenclature;
  Map<String, List<IikoNomenclatureProduct>> _productsByGroup = {};
  String? _selectedDepartmentId;
  final Set<String> _selectedGroupIds = {};
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final nomenclature =
          await _service.getNomenclature(widget.token, widget.organizationId);
      final byGroup = <String, List<IikoNomenclatureProduct>>{};
      for (final p in nomenclature.products) {
        if (p.groupId == null) continue;
        byGroup.putIfAbsent(p.groupId!, () => []).add(p);
      }
      if (!mounted) return;
      setState(() {
        _nomenclature = nomenclature;
        _productsByGroup = byGroup;
        // По умолчанию отмечаем все непустые группы — так проще
        // "импортировать всё" одним нажатием, а ненужное снять руками.
        _selectedGroupIds.addAll(byGroup.keys);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить номенклатуру. Проверьте интернет.';
        _loading = false;
      });
    }
  }

  int get _selectedProductCount => _selectedGroupIds.fold(
      0, (sum, gid) => sum + (_productsByGroup[gid]?.length ?? 0));

  Future<void> _import() async {
    final departmentId = _selectedDepartmentId;
    if (departmentId == null || _selectedGroupIds.isEmpty) return;

    setState(() => _importing = true);
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final groups = {for (final g in _nomenclature!.groups) g.id: g};

    var newCategories = 0, newProducts = 0, skippedDuplicates = 0;
    var counter = 0;
    String nextId() => '${DateTime.now().millisecondsSinceEpoch}_imp_${counter++}';

    for (final groupId in _selectedGroupIds) {
      final group = groups[groupId];
      final products = _productsByGroup[groupId];
      if (group == null || products == null || products.isEmpty) continue;

      // Не дублируем категорию, если в выбранном отделе уже есть категория
      // с таким же названием (например, повторный импорт или совпадение
      // с ручной категорией) — используем существующую.
      final existingCategory = repo.data.categories
          .where((c) =>
              c.departmentId == departmentId &&
              c.name.trim().toLowerCase() == group.name.trim().toLowerCase())
          .toList();
      final categoryId = existingCategory.isNotEmpty
          ? existingCategory.first.id
          : repo.addCategoryWithId(nextId(), group.name, departmentId);
      if (existingCategory.isEmpty) newCategories++;

      for (final product in products) {
        if (repo.isDuplicateProduct(product.name, categoryId)) {
          skippedDuplicates++;
          continue;
        }
        final unit = (product.measureUnit == null || product.measureUnit!.isEmpty)
            ? 'шт'
            : product.measureUnit!;
        repo.addProductWithId(nextId(), product.name, unit, categoryId);
        newProducts++;
      }
    }

    if (!mounted) return;
    setState(() => _importing = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Импортировано: $newCategories категори${newCategories == 1 ? 'я' : 'и'}, '
        '$newProducts товар${newProducts == 1 ? '' : 'ов'}'
        '${skippedDuplicates > 0 ? ', пропущено дублей: $skippedDuplicates' : ''}',
      ),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final departments = ref.watch(settingsRepositoryProvider).departments;

    return Scaffold(
      appBar: AppBar(title: const Text('Импорт товаров из iiko')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _DepartmentPicker(
                        departments: departments,
                        selectedId: _selectedDepartmentId,
                        isDark: isDark,
                        onSelect: (id) =>
                            setState(() => _selectedDepartmentId = id),
                      ),
                    ),
                    Expanded(
                      child: _productsByGroup.isEmpty
                          ? Center(
                              child: Text('В номенклатуре iiko нет товаров',
                                  style: TextStyle(color: AppColors.muted)))
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: _nomenclature!.groups
                                  .where((g) =>
                                      (_productsByGroup[g.id]?.isNotEmpty ?? false))
                                  .map((g) {
                                final count = _productsByGroup[g.id]!.length;
                                final checked = _selectedGroupIds.contains(g.id);
                                return CheckboxListTile(
                                  value: checked,
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _selectedGroupIds.add(g.id);
                                    } else {
                                      _selectedGroupIds.remove(g.id);
                                    }
                                  }),
                                  activeColor: AppColors.orange,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(g.name,
                                      style: TextStyle(color: textColor, fontSize: 14)),
                                  subtitle: Text('$count товар${count == 1 ? '' : count < 5 ? 'а' : 'ов'}',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                );
                              }).toList(),
                            ),
                    ),
                    SafeArea(
                      minimum: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedDepartmentId == null ||
                                  _selectedGroupIds.isEmpty ||
                                  _importing)
                              ? null
                              : _import,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _importing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_selectedDepartmentId == null
                                  ? 'Сначала выберите отдел'
                                  : 'Импортировать ($_selectedProductCount)'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DepartmentPicker extends StatelessWidget {
  final List<DepartmentModel> departments;
  final String? selectedId;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _DepartmentPicker({
    required this.departments,
    required this.selectedId,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Импортировать в отдел:',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: departments.map((d) {
            final selected = d.id == selectedId;
            return ChoiceChip(
              label: Text(d.name),
              selected: selected,
              onSelected: (_) => onSelect(d.id),
              selectedColor: AppColors.orange.withOpacity(0.2),
              labelStyle: TextStyle(
                color: selected ? AppColors.orange : AppColors.muted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
