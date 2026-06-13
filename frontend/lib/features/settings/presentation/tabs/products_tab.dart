import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/shared/widgets/animated_list_item.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

class ProductsTab extends ConsumerStatefulWidget {
  const ProductsTab({super.key});

  @override
  ConsumerState<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<ProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDeptId;
  String? _selectedCatId;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products, List<CategoryModel> categories) {
    List<ProductModel> filtered = products;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedDeptId != null) {
      final catIds = categories
          .where((c) => c.departmentId == _selectedDeptId)
          .map((c) => c.id)
          .toSet();
      filtered = filtered.where((p) => catIds.contains(p.categoryId)).toList();
    }
    if (_selectedCatId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCatId).toList();
    }
    return filtered;
  }

  // Универсальный диалог выбора значения
  Future<String?> _showOptionsDialog(BuildContext context, String title, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(options[i]),
          onTap: () => Navigator.pop(context, options[i]),
        ),
      ),
    );
  }

  // Каскадный выбор отдела и категории
  Future<void> _changeDepartmentAndCategory(
    BuildContext context,
    SettingsRepository repo,
    List<DepartmentModel> departments,
    List<CategoryModel> allCategories,
  ) async {
    if (_selectedIds.isEmpty) return;

    // 1. Выбор отдела
    final deptNames = departments.map((d) => d.name).toList();
    final deptName = await _showOptionsDialog(context, 'Выберите отдел', deptNames);
    if (deptName == null) return;
    final dept = departments.firstWhere((d) => d.name == deptName);

    // 2. Выбор категории в этом отделе
    final catsInDept = allCategories.where((c) => c.departmentId == dept.id).toList();
    if (catsInDept.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('В этом отделе нет категорий. Сначала создайте категорию.')),
      );
      return;
    }
    final catNames = catsInDept.map((c) => c.name).toList();
    final catName = await _showOptionsDialog(context, 'Выберите категорию', catNames);
    if (catName == null) return;
    final cat = catsInDept.firstWhere((c) => c.name == catName);

    // Применяем к выбранным товарам
    for (final id in _selectedIds.toList()) {
      final product = repo.state.products.firstWhere((p) => p.id == id);
      repo.updateProduct(id, product.name, product.unit,
          newCategoryId: cat.id, newInventoryUnit: product.inventoryUnit);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Отдел и категория изменены у ${_selectedIds.length} товаров')),
    );
    setState(() {
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  // Диалог для изменения единицы или категории (уже был)
  Future<void> _showBatchChangeDialog({
    required BuildContext context,
    required SettingsRepository repo,
    required List<String> ids,
    required String title,
    required List<String> options,
    required void Function(SettingsRepository, String id, String newValue) onApply,
  }) async {
    final result = await _showOptionsDialog(context, title, options);
    if (result != null) {
      for (final id in ids) {
        onApply(repo, id, result);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title изменено у ${ids.length} товаров')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(settingsRepositoryProvider).products;
    final categories = ref.watch(settingsRepositoryProvider).categories;
    final departments = ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _filteredProducts(products, categories);
    final availableCategories = _selectedDeptId == null
        ? categories
        : categories.where((c) => c.departmentId == _selectedDeptId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selectedIds.clear();
              });
            },
            child: Text(_selectMode ? 'Отмена' : 'Выбрать'),
          ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(heroTag: 'add', onPressed: () => _showAdd(context, repo, departments, categories, l10n), child: const Icon(Icons.add)),
                const SizedBox(height: 8),
                FloatingActionButton(heroTag: 'bulk', onPressed: () => _showBulk(context, repo, departments, categories, l10n), child: const Icon(Icons.playlist_add)),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildDeptChip(null, 'Все отделы', isDark),
                ...departments.map((d) => _buildDeptChip(d.id, d.name, isDark)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildCatChip(null, 'Все категории', isDark),
                ...availableCategories.map((c) => _buildCatChip(c.id, c.name, isDark)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.product, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final p = filtered[index];
                      final cat = categories.firstWhere((c) => c.id == p.categoryId, orElse: () => CategoryModel(id: '', name: 'Без категории', departmentId: ''));
                      final dept = departments.firstWhere((d) => d.id == cat.departmentId, orElse: () => DepartmentModel(id: '', name: 'Неизвестно', icon: Icons.help));
                      final isSelected = _selectedIds.contains(p.id);

                      return AnimatedListItem(
                        child: Card(
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          child: ListTile(
                            leading: _selectMode
                                ? Checkbox(value: isSelected, onChanged: (v) { setState(() { if (v == true) _selectedIds.add(p.id); else _selectedIds.remove(p.id); }); }, activeColor: Colors.orange)
                                : null,
                            title: Text(p.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                            subtitle: Text('Заявка: ${p.unit} | Инвент: ${p.inventoryUnit} | ${dept.name} → ${cat.name}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                            trailing: _selectMode ? null : IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, repo, p, l10n)),
                            onTap: _selectMode
                                ? () { setState(() { if (isSelected) _selectedIds.remove(p.id); else _selectedIds.add(p.id); }); }
                                : () => _showEdit(context, repo, p, departments, categories, l10n),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_selectMode && _selectedIds.isNotEmpty)
            SafeArea(
              child: Container(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Text('Выбрано: ${_selectedIds.length}'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.apartment),
                        label: const Text('Отдел'),
                        onPressed: () => _changeDepartmentAndCategory(context, repo, departments, categories),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.category),
                        label: const Text('Категорию'),
                        onPressed: () {
                          final catNames = categories.map((c) => c.name).toSet().toList();
                          _showBatchChangeDialog(
                            context: context, repo: repo, ids: _selectedIds.toList(), title: 'Категория', options: catNames,
                            onApply: (repo, id, newValue) {
                              final cat = categories.firstWhere((c) => c.name == newValue);
                              final product = repo.state.products.firstWhere((p) => p.id == id);
                              repo.updateProduct(id, product.name, product.unit, newCategoryId: cat.id, newInventoryUnit: product.inventoryUnit);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.straighten),
                        label: const Text('Ед. заявки'),
                        onPressed: () {
                          final units = ['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'];
                          _showBatchChangeDialog(
                            context: context, repo: repo, ids: _selectedIds.toList(), title: 'Ед. изм. (заявка)', options: units,
                            onApply: (repo, id, newValue) {
                              final product = repo.state.products.firstWhere((p) => p.id == id);
                              repo.updateProduct(id, product.name, newValue, newCategoryId: product.categoryId, newInventoryUnit: product.inventoryUnit);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Ед. инвент.'),
                        onPressed: () {
                          final units = ['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'];
                          _showBatchChangeDialog(
                            context: context, repo: repo, ids: _selectedIds.toList(), title: 'Ед. изм. (инвент.)', options: units,
                            onApply: (repo, id, newValue) {
                              final product = repo.state.products.firstWhere((p) => p.id == id);
                              repo.updateProduct(id, product.name, product.unit, newCategoryId: product.categoryId, newInventoryUnit: newValue);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeptChip(String? id, String label, bool isDark) {
    final selected = _selectedDeptId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          setState(() {
            _selectedDeptId = val ? id : null;
            _selectedCatId = null;
          });
        },
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
      ),
    );
  }

  Widget _buildCatChip(String? id, String label, bool isDark) {
    final selected = _selectedCatId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) => setState(() => _selectedCatId = val ? id : null),
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
      ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo, ProductModel p, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirm),
        content: Text('${l.deleteConfirm} «${p.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              repo.deleteProduct(p.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.successProductDeleted} «${p.name}»')),
              );
            },
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAdd(
    BuildContext c,
    SettingsRepository r,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
  ) {
    final ctrl = TextEditingController();
    String? selectedDeptId = depts.isNotEmpty ? depts.first.id : null;
    String? selectedCatId;
    String sUnit = 'кг';
    String sInvUnit = 'кг';

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = selectedDeptId == null
              ? allCats
              : allCats.where((cat) => cat.departmentId == selectedDeptId).toList();
          if (selectedCatId != null && !filteredCats.any((cat) => cat.id == selectedCatId)) {
            selectedCatId = null;
          }
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }

          return AlertDialog(
            title: Text(l.addProduct),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: depts.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: filteredCats.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                  onChanged: (v) => set(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Название')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (заявка)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sInvUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sInvUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (инвент.)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty && selectedCatId != null) {
                    Navigator.pop(ctx);
                    r.addProduct(ctrl.text, sUnit, selectedCatId!, inventoryUnit: sInvUnit);
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text('${l.successProductAdded} «${ctrl.text}»')),
                    );
                  }
                },
                child: Text(l.add),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulk(
    BuildContext c,
    SettingsRepository r,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
  ) {
    final ctrl = TextEditingController();
    String? selectedDeptId = depts.isNotEmpty ? depts.first.id : null;
    String? selectedCatId;
    String sUnit = 'шт';
    String sInvUnit = 'шт';

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = selectedDeptId == null
              ? allCats
              : allCats.where((cat) => cat.departmentId == selectedDeptId).toList();
          if (selectedCatId != null && !filteredCats.any((cat) => cat.id == selectedCatId)) {
            selectedCatId = null;
          }
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }

          return AlertDialog(
            title: Text(l.bulkAddProducts),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: depts.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: filteredCats.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                  onChanged: (v) => set(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Товары, каждый с новой строки',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (заявка)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sInvUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sInvUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (инвент.)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  final names = ctrl.text
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  if (names.isNotEmpty && selectedCatId != null) {
                    Navigator.pop(ctx);
                    r.bulkAddProducts(names, sUnit, selectedCatId!, defaultInventoryUnit: sInvUnit);
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text('${l.successProductsBulkAdded} (${names.length})')),
                    );
                  }
                },
                child: Text(l.add),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEdit(
    BuildContext c,
    SettingsRepository r,
    ProductModel p,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
  ) {
    final ctrl = TextEditingController(text: p.name);
    final currentCat = allCats.firstWhere(
      (cat) => cat.id == p.categoryId,
      orElse: () => CategoryModel(id: '', name: '', departmentId: ''),
    );
    String? selectedDeptId = currentCat.departmentId.isNotEmpty
        ? currentCat.departmentId
        : (depts.isNotEmpty ? depts.first.id : null);
    String? selectedCatId = p.categoryId;
    String sUnit = p.unit;
    String sInvUnit = p.inventoryUnit;

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = selectedDeptId == null
              ? allCats
              : allCats.where((cat) => cat.departmentId == selectedDeptId).toList();
          if (selectedCatId != null && !filteredCats.any((cat) => cat.id == selectedCatId)) {
            selectedCatId = null;
          }
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }

          return AlertDialog(
            title: Text(l.editProduct),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDeptId,
                  items: depts.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                  onChanged: (v) {
                    set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Отдел'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: filteredCats.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                  onChanged: (v) => set(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Категория'),
                ),
                const SizedBox(height: 12),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Название')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (заявка)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sInvUnit,
                  items: <String>['кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка']
                      .map<DropdownMenuItem<String>>((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => set(() => sInvUnit = v!),
                  decoration: const InputDecoration(labelText: 'Ед. изм. (инвент.)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty && selectedCatId != null) {
                    Navigator.pop(ctx);
                    r.updateProduct(p.id, ctrl.text, sUnit,
                        newCategoryId: selectedCatId, newInventoryUnit: sInvUnit);
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text('${l.successProductUpdated} «${ctrl.text}»')),
                    );
                  }
                },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }
}