import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_batch_dialogs.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_batch_panel.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_dialogs.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_filters.dart';
import 'package:horeca_app/features/settings/presentation/tabs/products_tab_list.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/department_model.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';

/// Экран "Товары" (уровень 3 иерархии Отдел → Категория → Товар): поиск,
/// фильтры по отделу/категории, список товаров и массовое редактирование.
///
/// Диалоги вынесены в products_tab_dialogs.dart и
/// products_tab_batch_dialogs.dart, поиск/фильтры — в products_tab_filters.dart,
/// список товаров — в products_tab_list.dart, панель массового
/// редактирования — в products_tab_batch_panel.dart, мелкие виджеты — в
/// products_tab_widgets.dart.
class ProductsTab extends ConsumerStatefulWidget {
  // Уровень 3 иерархии "Настройка товаров и отделов": при открытии из
  // конкретной категории (CatalogCategoriesScreen) сюда передаётся отдел
  // и категория, чтобы список товаров сразу открывался отфильтрованным —
  // фильтры при этом остаются на экране, их можно расширить обратно.
  final DepartmentModel? initialDepartment;
  final CategoryModel? initialCategory;
  const ProductsTab({super.key, this.initialDepartment, this.initialCategory});

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
  void initState() {
    super.initState();
    _selectedDeptId = widget.initialDepartment?.id;
    _selectedCatId = widget.initialCategory?.id;
  }

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
          .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = ref.watch(settingsRepositoryProvider).products;
    final categories = ref.watch(settingsRepositoryProvider).categories;
    final departments = ref.watch(settingsRepositoryProvider).departments;
    final repo = ref.read(settingsRepositoryProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Отдел → Категория → Товар: сортируем список товаров по этой же
    // иерархии (а не в порядке добавления), чтобы он не превращался
    // в хаос после нескольких правок — так же, как в списке категорий.
    final deptOrder = {
      for (var i = 0; i < departments.length; i++) departments[i].id: i
    };
    String catNameOf(String? categoryId) => categories
        .firstWhere((c) => c.id == categoryId,
            orElse: () => CategoryModel(id: '', name: '', departmentId: ''))
        .name;
    String deptIdOfCategory(String? categoryId) => categories
        .firstWhere((c) => c.id == categoryId,
            orElse: () => CategoryModel(id: '', name: '', departmentId: ''))
        .departmentId;

    final filtered = _filteredProducts(products, categories)
      ..sort((a, b) {
        final byDept = (deptOrder[deptIdOfCategory(a.categoryId)] ?? 999)
            .compareTo(deptOrder[deptIdOfCategory(b.categoryId)] ?? 999);
        if (byDept != 0) return byDept;
        final byCat = catNameOf(a.categoryId)
            .toLowerCase()
            .compareTo(catNameOf(b.categoryId).toLowerCase());
        if (byCat != 0) return byCat;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final availableCategories = _selectedDeptId == null
        ? categories
        : categories.where((c) => c.departmentId == _selectedDeptId).toList();

    // Раньше этот экран жил внутри TabBarView "Настроек" и не был отдельным
    // маршрутом — теперь до него доходят через Отдел → Категория, поэтому
    // нужны своя кнопка "назад" и заголовок с контекстом (категория),
    // а также собственный градиентный фон, как у остальных экранов,
    // открываемых через Navigator.push.
    final title = widget.initialCategory?.name ?? 'Товары';

    final batchPanel = buildProductBatchEditPanel(
      context: context,
      repo: repo,
      departments: departments,
      categories: categories,
      products: products,
      selectedIds: _selectedIds,
      isDark: isDark,
      selectMode: _selectMode,
      setState: setState,
      onExitSelectMode: () => _selectMode = false,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
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
              _selectMode ? l10n.cancel : 'Выбрать',
              style: const TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton(
              heroTag: 'bulk',
              onPressed: () => showBulkAddProductsDialog(
                context: context,
                repo: repo,
                depts: departments,
                allCats: categories,
                l: l10n,
                isDark: isDark,
                initialDepartmentId: widget.initialDepartment?.id,
                initialCategoryId: widget.initialCategory?.id,
              ),
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.playlist_add_rounded),
            ),
      body: Stack(children: [
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                Color(0xFF0F1629),
                                Color(0xFF1A1040),
                                Color(0xFF0D1F35)
                              ]
                            : const [
                                Color(0xFFEEF2FF),
                                Color(0xFFF5F7FF),
                                Color(0xFFEEF2FF)
                              ])))),
        SafeArea(
          child: Column(
            children: [
              buildProductsSearchField(
                controller: _searchController,
                searchQuery: _searchQuery,
                isDark: isDark,
                l10n: l10n,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
              ),
              buildDepartmentFilterRow(
                departments: departments,
                selectedDeptId: _selectedDeptId,
                isDark: isDark,
                onSelect: (id) => setState(() {
                  _selectedDeptId = id;
                  _selectedCatId = null;
                }),
              ),
              const SizedBox(height: 6),
              buildCategoryFilterRow(
                availableCategories: availableCategories,
                selectedCatId: _selectedCatId,
                isDark: isDark,
                onSelect: (id) => setState(() => _selectedCatId = id),
              ),
              const SizedBox(height: 8),
              buildProductsListView(
                filtered: filtered,
                categories: categories,
                departments: departments,
                isDark: isDark,
                selectMode: _selectMode,
                selectedIds: _selectedIds,
                onSetMinStock: (p) =>
                    showMinStockDialog(context, repo, p, isDark),
                onDelete: (p) =>
                    confirmDeleteProduct(context, repo, p, l10n, isDark),
                onEdit: (p) => showEditProductDialog(
                  context: context,
                  repo: repo,
                  p: p,
                  depts: departments,
                  allCats: categories,
                  l: l10n,
                  isDark: isDark,
                ),
                onSelectChanged: (id, v) => setState(() {
                  if (v == true) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                }),
                onToggleSelect: (id) => setState(() {
                  if (_selectedIds.contains(id)) {
                    _selectedIds.remove(id);
                  } else {
                    _selectedIds.add(id);
                  }
                }),
              ),
              if (batchPanel != null) batchPanel,
            ],
          ),
        ),
      ]),
    );
  }
}
