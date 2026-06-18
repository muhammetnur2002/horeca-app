import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
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

  List<ProductModel> _filteredProducts(
      List<ProductModel> products, List<CategoryModel> categories) {
    List<ProductModel> filtered = products;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedDeptId != null) {
      final catIds = categories
          .where((c) => c.departmentId == _selectedDeptId)
          .map((c) => c.id)
          .toSet();
      filtered =
          filtered.where((p) => catIds.contains(p.categoryId)).toList();
    }
    if (_selectedCatId != null) {
      filtered =
          filtered.where((p) => p.categoryId == _selectedCatId).toList();
    }
    return filtered;
  }

  Future<String?> _showOptionsDialog(
      BuildContext context, String title, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard.withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                ...options.map((o) => ListTile(
                      title: Text(o),
                      onTap: () => Navigator.pop(context, o),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeDepartmentAndCategory(
    BuildContext context,
    SettingsRepository repo,
    List<DepartmentModel> departments,
    List<CategoryModel> allCategories,
  ) async {
    if (_selectedIds.isEmpty) return;
    final deptNames = departments.map((d) => d.name).toList();
    final deptName =
        await _showOptionsDialog(context, 'Выберите отдел', deptNames);
    if (deptName == null) return;
    final dept = departments.firstWhere((d) => d.name == deptName);
    final catsInDept =
        allCategories.where((c) => c.departmentId == dept.id).toList();
    if (catsInDept.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('В этом отделе нет категорий')));
      return;
    }
    final catNames = catsInDept.map((c) => c.name).toList();
    final catName =
        await _showOptionsDialog(context, 'Выберите категорию', catNames);
    if (catName == null) return;
    final cat = catsInDept.firstWhere((c) => c.name == catName);
    for (final id in _selectedIds.toList()) {
      final product =
          repo.state.products.firstWhere((p) => p.id == id);
      repo.updateProduct(id, product.name, product.unit,
          newCategoryId: cat.id,
          newInventoryUnit: product.inventoryUnit);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Изменено у ${_selectedIds.length} товаров'),
      backgroundColor: AppColors.darkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
    setState(() {
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  Future<void> _showBatchChangeDialog({
    required BuildContext context,
    required SettingsRepository repo,
    required List<String> ids,
    required String title,
    required List<String> options,
    required void Function(SettingsRepository, String id, String newValue)
        onApply,
  }) async {
    final result =
        await _showOptionsDialog(context, title, options);
    if (result != null) {
      for (final id in ids) {
        onApply(repo, id, result);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$title изменено у ${ids.length} товаров'),
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(settingsRepositoryProvider).products;
    final categories =
        ref.watch(settingsRepositoryProvider).categories;
    final departments =
        ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final filtered = _filteredProducts(products, categories);
    final availableCategories = _selectedDeptId == null
        ? categories
        : categories
            .where((c) => c.departmentId == _selectedDeptId)
            .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Товары',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selectedIds.clear();
              });
            },
            child: Text(
              _selectMode ? 'Отмена' : 'Выбрать',
              style: const TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () => _showAdd(
                      context, repo, departments, categories, l10n, isDark),
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'bulk',
                  onPressed: () => _showBulk(
                      context, repo, departments, categories, l10n, isDark),
                  backgroundColor: AppColors.darkCard2,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.playlist_add_rounded),
                ),
              ],
            ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white
                        .withOpacity(isDark ? 0.06 : 0.55),
                    border: Border.all(
                      color: Colors.white
                          .withOpacity(isDark ? 0.1 : 0.8),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchProducts,
                      hintStyle:
                          TextStyle(color: AppColors.muted),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                  ),
                ),
              ),
            ),
          ),

          // Фильтр отделов
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip(null, 'Все отделы', isDark,
                    _selectedDeptId, (id) {
                  setState(() {
                    _selectedDeptId = id;
                    _selectedCatId = null;
                  });
                }, AppColors.orange),
                ...departments.map((d) => _buildChip(
                    d.id, d.name, isDark, _selectedDeptId, (id) {
                  setState(() {
                    _selectedDeptId = id;
                    _selectedCatId = null;
                  });
                }, AppColors.orange)),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Фильтр категорий
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip(null, 'Все категории', isDark,
                    _selectedCatId, (id) {
                  setState(() => _selectedCatId = id);
                }, AppColors.green),
                ...availableCategories.map((c) => _buildChip(
                    c.id, c.name, isDark, _selectedCatId, (id) {
                  setState(() => _selectedCatId = id);
                }, AppColors.green)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Список товаров
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color:
                                AppColors.muted.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(24),
                          ),
                          child: Icon(
                              Icons.inventory_2_outlined,
                              size: 36,
                              color: AppColors.muted
                                  .withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text('Нет товаров',
                            style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 120),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final p = filtered[index];
                      final cat = categories.firstWhere(
                        (c) => c.id == p.categoryId,
                        orElse: () => CategoryModel(
                            id: '',
                            name: 'Без категории',
                            departmentId: ''),
                      );
                      final dept = departments.firstWhere(
                        (d) => d.id == cat.departmentId,
                        orElse: () => DepartmentModel(
                            id: '',
                            name: 'Неизвестно',
                            icon: Icons.help),
                      );
                      final isSelected =
                          _selectedIds.contains(p.id);
                      return _ProductItem(
                        p: p,
                        catName: cat.name,
                        deptName: dept.name,
                        isDark: isDark,
                        isSelected: isSelected,
                        selectMode: _selectMode,
                        onSelect: (v) {
                          setState(() {
                            if (v == true)
                              _selectedIds.add(p.id);
                            else
                              _selectedIds.remove(p.id);
                          });
                        },
                        onDelete: () => _confirmDelete(
                            context, repo, p, l10n, isDark),
                        onTap: _selectMode
                            ? () {
                                setState(() {
                                  if (isSelected)
                                    _selectedIds.remove(p.id);
                                  else
                                    _selectedIds.add(p.id);
                                });
                              }
                            : () => _showEdit(context, repo, p,
                                departments, categories, l10n, isDark),
                      );
                    },
                  ),
          ),

          // Панель массового редактирования
          if (_selectMode && _selectedIds.isNotEmpty)
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: isDark
                      ? AppColors.darkSurface.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выбрано: ${_selectedIds.length}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _BatchBtn(
                                icon: Icons.apartment_rounded,
                                label: 'Отдел',
                                onTap: () =>
                                    _changeDepartmentAndCategory(
                                        context,
                                        repo,
                                        departments,
                                        categories),
                              ),
                              const SizedBox(width: 8),
                              _BatchBtn(
                                icon: Icons.folder_outlined,
                                label: 'Категорию',
                                onTap: () {
                                  final catNames = categories
                                      .map((c) => c.name)
                                      .toSet()
                                      .toList();
                                  _showBatchChangeDialog(
                                    context: context,
                                    repo: repo,
                                    ids: _selectedIds.toList(),
                                    title: 'Категория',
                                    options: catNames,
                                    onApply:
                                        (repo, id, newValue) {
                                      final cat =
                                          categories.firstWhere(
                                              (c) =>
                                                  c.name ==
                                                  newValue);
                                      final product = repo
                                          .state.products
                                          .firstWhere(
                                              (p) => p.id == id);
                                      repo.updateProduct(
                                          id,
                                          product.name,
                                          product.unit,
                                          newCategoryId: cat.id,
                                          newInventoryUnit: product
                                              .inventoryUnit);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _BatchBtn(
                                icon: Icons.straighten_rounded,
                                label: 'Ед. заявки',
                                onTap: () {
                                  final units = [
                                    'кг', 'гр', 'л', 'мл',
                                    'шт', 'коробка', 'упаковка'
                                  ];
                                  _showBatchChangeDialog(
                                    context: context,
                                    repo: repo,
                                    ids: _selectedIds.toList(),
                                    title: 'Ед. изм. (заявка)',
                                    options: units,
                                    onApply:
                                        (repo, id, newValue) {
                                      final product = repo
                                          .state.products
                                          .firstWhere(
                                              (p) => p.id == id);
                                      repo.updateProduct(
                                          id,
                                          product.name,
                                          newValue,
                                          newCategoryId:
                                              product.categoryId,
                                          newInventoryUnit: product
                                              .inventoryUnit);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _BatchBtn(
                                icon: Icons.edit_rounded,
                                label: 'Ед. инвент.',
                                onTap: () {
                                  final units = [
                                    'кг', 'гр', 'л', 'мл',
                                    'шт', 'коробка', 'упаковка'
                                  ];
                                  _showBatchChangeDialog(
                                    context: context,
                                    repo: repo,
                                    ids: _selectedIds.toList(),
                                    title: 'Ед. изм. (инвент.)',
                                    options: units,
                                    onApply:
                                        (repo, id, newValue) {
                                      final product = repo
                                          .state.products
                                          .firstWhere(
                                              (p) => p.id == id);
                                      repo.updateProduct(
                                          id,
                                          product.name,
                                          product.unit,
                                          newCategoryId:
                                              product.categoryId,
                                          newInventoryUnit:
                                              newValue);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String? id,
    String label,
    bool isDark,
    String? selectedId,
    ValueChanged<String?> onTap,
    Color color,
  ) {
    final selected = selectedId == id;
    return GestureDetector(
      onTap: () => onTap(selected ? null : id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? color
              : Colors.white.withOpacity(isDark ? 0.06 : 0.5),
          border: Border.all(
            color: selected
                ? color
                : Colors.white.withOpacity(isDark ? 0.1 : 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SettingsRepository repo,
      ProductModel p, AppLocalizations l, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить товар?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text('«${p.name}» будет удалён.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              repo.deleteProduct(p.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('«${p.name}» удалён'),
                backgroundColor: AppColors.darkCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  AlertDialog _buildProductDialog({
    required BuildContext ctx,
    required String title,
    required StateSetter set,
    required TextEditingController ctrl,
    required List<DepartmentModel> depts,
    required List<CategoryModel> allCats,
    required String? selectedDeptId,
    required String? selectedCatId,
    required String sUnit,
    required String sInvUnit,
    required bool isDark,
    required ValueChanged<String?> onDeptChanged,
    required ValueChanged<String?> onCatChanged,
    required ValueChanged<String> onUnitChanged,
    required ValueChanged<String> onInvUnitChanged,
    required VoidCallback onSave,
    required AppLocalizations l,
    required bool isEdit,
  }) {
    final filteredCats = selectedDeptId == null
        ? allCats
        : allCats
            .where((cat) => cat.departmentId == selectedDeptId)
            .toList();
    final units = [
      'кг', 'гр', 'л', 'мл', 'шт', 'коробка', 'упаковка'
    ];

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedDeptId,
              dropdownColor:
                  isDark ? AppColors.darkCard : Colors.white,
              items: depts
                  .map((d) => DropdownMenuItem(
                      value: d.id, child: Text(d.name)))
                  .toList(),
              onChanged: onDeptChanged,
              decoration:
                  const InputDecoration(labelText: 'Отдел'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: filteredCats.any((c) => c.id == selectedCatId)
                  ? selectedCatId
                  : (filteredCats.isNotEmpty
                      ? filteredCats.first.id
                      : null),
              dropdownColor:
                  isDark ? AppColors.darkCard : Colors.white,
              items: filteredCats
                  .map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: onCatChanged,
              decoration: const InputDecoration(
                  labelText: 'Категория'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: !isEdit,
              decoration: InputDecoration(
                hintText: 'Название товара',
                prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: sUnit,
              dropdownColor:
                  isDark ? AppColors.darkCard : Colors.white,
              items: units
                  .map((u) => DropdownMenuItem(
                      value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => onUnitChanged(v!),
              decoration: const InputDecoration(
                  labelText: 'Ед. изм. (заявка)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: sInvUnit,
              dropdownColor:
                  isDark ? AppColors.darkCard : Colors.white,
              items: units
                  .map((u) => DropdownMenuItem(
                      value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => onInvUnitChanged(v!),
              decoration: const InputDecoration(
                  labelText: 'Ед. изм. (инвент.)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel,
              style: TextStyle(color: AppColors.muted)),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(isEdit ? l.save : l.add),
        ),
      ],
    );
  }

  void _showAdd(
    BuildContext c,
    SettingsRepository r,
    List<DepartmentModel> depts,
    List<CategoryModel> allCats,
    AppLocalizations l,
    bool isDark,
  ) {
    final ctrl = TextEditingController();
    String? selectedDeptId =
        depts.isNotEmpty ? depts.first.id : null;
    String? selectedCatId;
    String sUnit = 'кг';
    String sInvUnit = 'кг';

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = selectedDeptId == null
              ? allCats
              : allCats
                  .where(
                      (cat) => cat.departmentId == selectedDeptId)
                  .toList();
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }
          return _buildProductDialog(
            ctx: ctx,
            title: l.addProduct,
            set: set,
            ctrl: ctrl,
            depts: depts,
            allCats: allCats,
            selectedDeptId: selectedDeptId,
            selectedCatId: selectedCatId,
            sUnit: sUnit,
            sInvUnit: sInvUnit,
            isDark: isDark,
            onDeptChanged: (v) => set(() {
              selectedDeptId = v;
              selectedCatId = null;
            }),
            onCatChanged: (v) => set(() => selectedCatId = v),
            onUnitChanged: (v) => set(() => sUnit = v),
            onInvUnitChanged: (v) => set(() => sInvUnit = v),
            onSave: () {
              if (ctrl.text.isNotEmpty && selectedCatId != null) {
                Navigator.pop(ctx);
                r.addProduct(ctrl.text, sUnit, selectedCatId!,
                    inventoryUnit: sInvUnit);
                ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                  content:
                      Text('«${ctrl.text}» добавлен'),
                  backgroundColor: AppColors.darkCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            l: l,
            isEdit: false,
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
    bool isDark,
  ) {
    final ctrl = TextEditingController();
    String? selectedDeptId =
        depts.isNotEmpty ? depts.first.id : null;
    String? selectedCatId;
    String sUnit = 'шт';
    String sInvUnit = 'шт';

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) {
          final filteredCats = selectedDeptId == null
              ? allCats
              : allCats
                  .where(
                      (cat) => cat.departmentId == selectedDeptId)
                  .toList();
          if (selectedCatId == null && filteredCats.isNotEmpty) {
            selectedCatId = filteredCats.first.id;
          }
          final units = [
            'кг', 'гр', 'л', 'мл',
            'шт', 'коробка', 'упаковка'
          ];
          return AlertDialog(
            backgroundColor:
                isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(l.bulkAddProducts,
                style: const TextStyle(
                    fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDeptId,
                    dropdownColor: isDark
                        ? AppColors.darkCard
                        : Colors.white,
                    items: depts
                        .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => set(() {
                      selectedDeptId = v;
                      selectedCatId = null;
                    }),
                    decoration: const InputDecoration(
                        labelText: 'Отдел'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: filteredCats.any(
                            (c) => c.id == selectedCatId)
                        ? selectedCatId
                        : (filteredCats.isNotEmpty
                            ? filteredCats.first.id
                            : null),
                    dropdownColor: isDark
                        ? AppColors.darkCard
                        : Colors.white,
                    items: filteredCats
                        .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        set(() => selectedCatId = v),
                    decoration: const InputDecoration(
                        labelText: 'Категория'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Товары, каждый с новой строки',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: sUnit,
                    dropdownColor: isDark
                        ? AppColors.darkCard
                        : Colors.white,
                    items: units
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) =>
                        set(() => sUnit = v!),
                    decoration: const InputDecoration(
                        labelText: 'Ед. изм. (заявка)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: sInvUnit,
                    dropdownColor: isDark
                        ? AppColors.darkCard
                        : Colors.white,
                    items: units
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) =>
                        set(() => sInvUnit = v!),
                    decoration: const InputDecoration(
                        labelText: 'Ед. изм. (инвент.)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel,
                    style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () {
                  final names = ctrl.text
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  if (names.isNotEmpty &&
                      selectedCatId != null) {
                    Navigator.pop(ctx);
                    r.bulkAddProducts(
    names, sUnit, selectedCatId!,
    defaultInventoryUnit: sInvUnit);
                    ScaffoldMessenger.of(c)
                        .showSnackBar(SnackBar(
                      content: Text(
                          'Добавлено ${names.length} товаров'),
                      backgroundColor: AppColors.darkCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
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
    bool isDark,
  ) {
    final ctrl = TextEditingController(text: p.name);
    final currentCat = allCats.firstWhere(
      (cat) => cat.id == p.categoryId,
      orElse: () =>
          CategoryModel(id: '', name: '', departmentId: ''),
    );
    String? selectedDeptId =
        currentCat.departmentId.isNotEmpty
            ? currentCat.departmentId
            : (depts.isNotEmpty ? depts.first.id : null);
    String? selectedCatId = p.categoryId;
    String sUnit = p.unit;
    String sInvUnit = p.inventoryUnit;

    showDialog(
      context: c,
      builder: (ctx) => StatefulBuilder(
        builder: (_, set) => _buildProductDialog(
          ctx: ctx,
          title: l.editProduct,
          set: set,
          ctrl: ctrl,
          depts: depts,
          allCats: allCats,
          selectedDeptId: selectedDeptId,
          selectedCatId: selectedCatId,
          sUnit: sUnit,
          sInvUnit: sInvUnit,
          isDark: isDark,
          onDeptChanged: (v) => set(() {
            selectedDeptId = v;
            selectedCatId = null;
          }),
          onCatChanged: (v) => set(() => selectedCatId = v),
          onUnitChanged: (v) => set(() => sUnit = v),
          onInvUnitChanged: (v) => set(() => sInvUnit = v),
          onSave: () {
            if (ctrl.text.isNotEmpty &&
                selectedCatId != null) {
              Navigator.pop(ctx);
              r.updateProduct(p.id, ctrl.text, sUnit,
                  newCategoryId: selectedCatId,
                  newInventoryUnit: sInvUnit);
              ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                content: Text('«${ctrl.text}» обновлён'),
                backgroundColor: AppColors.darkCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          l: l,
          isEdit: true,
        ),
      ),
    );
  }
}

// ── Карточка товара ───────────────────────────────────────────────────────
class _ProductItem extends StatelessWidget {
  final ProductModel p;
  final String catName;
  final String deptName;
  final bool isDark;
  final bool isSelected;
  final bool selectMode;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ProductItem({
    required this.p,
    required this.catName,
    required this.deptName,
    required this.isDark,
    required this.isSelected,
    required this.selectMode,
    required this.onSelect,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected
                  ? AppColors.orange.withOpacity(0.12)
                  : Colors.white
                      .withOpacity(isDark ? 0.06 : 0.55),
              border: Border.all(
                color: isSelected
                    ? AppColors.orange.withOpacity(0.4)
                    : Colors.white
                        .withOpacity(isDark ? 0.1 : 0.8),
              ),
            ),
            child: Row(
              children: [
                if (selectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: onSelect,
                    activeColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(4)),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          AppColors.orange.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.orange,
                        size: 18),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Заявка: ${p.unit} | Инвент: ${p.inventoryUnit} | $deptName → $catName',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!selectMode)
                  IconButton(
                    icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Кнопка массового редактирования ──────────────────────────────────────
class _BatchBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BatchBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.orange.withOpacity(0.12),
          border: Border.all(
              color: AppColors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.orange),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
