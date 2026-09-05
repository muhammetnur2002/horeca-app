import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/inventory/domain/usecases/inventory_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/category_model.dart';
import 'package:horeca_app/shared/models/product_model.dart';

/// Ввод остатков при инвентаризации.
///
/// Экран, на котором человек стоит у полки и вводит десятки, а то и сотни
/// значений подряд. Поэтому здесь три решения ради скорости:
///
///  * Список строится лениво. Раньше `ListView(children: ...)` создавал
///    строки сразу для всех товаров, включая те, что за экраном.
///  * У строк нет размытия фона. `BackdropFilter` на каждой строке — самая
///    дорогая операция для видеоядра телефона, и она повторялась столько
///    раз, сколько товаров. Стекло осталось, но нарисовано полупрозрачной
///    заливкой, а не размытием.
///  * Строка подписана только на своё значение. Нажатие «плюс» раньше
///    перестраивало весь список; теперь перерисовывается одна строка.
class InputRemainingStep extends ConsumerStatefulWidget {
  const InputRemainingStep({super.key});

  @override
  ConsumerState<InputRemainingStep> createState() => _InputRemainingStepState();
}

class _InputRemainingStepState extends ConsumerState<InputRemainingStep> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Плоский список: заголовки категорий и товары идут вперемешку, как
  /// на экране. Так `ListView.builder` строит ровно то, что видно.
  List<_Row> _buildRows(
    List<ProductModel> products,
    List<CategoryModel> categories,
    String? departmentId,
    List<String> selectedCategoryIds,
  ) {
    // Поиск по словарю вместо перебора: раньше для каждого товара
    // делался обход всех категорий, то есть сотни сравнений на кадр.
    final byId = {for (final c in categories) c.id: c};
    final selected = selectedCategoryIds.toSet();
    final query = _searchQuery.trim().toLowerCase();

    final grouped = <String, List<ProductModel>>{};
    for (final product in products) {
      final category = byId[product.categoryId];
      final categoryId = category?.id ?? '';
      if (!selected.contains(categoryId)) continue;

      if (departmentId != 'all' &&
          category != null &&
          category.departmentId.isNotEmpty &&
          category.departmentId != departmentId) {
        continue;
      }

      if (query.isNotEmpty && !product.name.toLowerCase().contains(query)) {
        continue;
      }

      grouped.putIfAbsent(category?.name ?? 'Без категории', () => []).add(product);
    }

    final rows = <_Row>[];
    for (final entry in grouped.entries) {
      rows.add(_Row.header(entry.key));
      rows.addAll(entry.value.map(_Row.product));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final departmentId =
        ref.watch(inventoryStateProvider.select((s) => s.departmentId));
    if (departmentId == null) return const SizedBox.shrink();

    final selectedCategoryIds = ref
        .watch(inventoryStateProvider.select((s) => s.selectedCategoryIds));
    final settings = ref.watch(settingsRepositoryProvider);
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rows = _buildRows(
      settings.products,
      settings.categories,
      departmentId,
      selectedCategoryIds,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
              : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
            child: _SearchField(
              controller: _searchCtrl,
              hasText: _searchQuery.isNotEmpty,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () => setState(() {
                _searchCtrl.clear();
                _searchQuery = '';
              }),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Ничего не найдено'
                          : 'Нет товаров',
                      style: TextStyle(color: palette.textMuted, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final product = row.product;
                      if (product == null) {
                        return _CategoryHeader(title: row.title!);
                      }
                      return _ProductRow(
                        key: ValueKey(product.id),
                        product: product,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Элемент плоского списка: либо заголовок категории, либо товар.
class _Row {
  const _Row.header(this.title) : product = null;
  const _Row.product(this.product) : title = null;

  final String? title;
  final ProductModel? product;
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.palette.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: palette.surface.withValues(alpha: 0.75),
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14, color: palette.textPrimary),
        decoration: InputDecoration(
          hintText: 'Поиск товара...',
          hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded,
              color: palette.textMuted, size: 20),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: palette.textMuted, size: 18),
                  tooltip: 'Очистить поиск',
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Строка товара.
///
/// Отдельный ConsumerWidget не ради красоты: он подписан только на остаток
/// своего товара, поэтому нажатие «плюс» перерисовывает одну строку,
/// а не весь список.
class _ProductRow extends ConsumerWidget {
  const _ProductRow({super.key, required this.product});

  final ProductModel product;

  double _remainingOf(InventoryState state) {
    for (final item in state.items) {
      if (item.productId == product.id) return item.remaining;
    }
    return 0;
  }

  void _set(WidgetRef ref, double value) {
    ref.read(inventoryStateProvider.notifier).updateItem(
          product.id,
          product.name,
          product.inventoryUnit,
          value < 0 ? 0 : value,
        );
  }

  Future<void> _showManualInput(
      BuildContext context, WidgetRef ref, double current) async {
    final controller = TextEditingController(
        text: current == 0 ? '' : _format(current));
    try {
      final entered = await showDialog<double>(
        context: context,
        builder: (dialogContext) {
          final palette = dialogContext.palette;
          return AlertDialog(
            title: Text(product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: product.inventoryUnit,
              ),
              onSubmitted: (_) => Navigator.pop(
                  dialogContext, _parse(controller.text) ?? current),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Отмена',
                    style: TextStyle(color: palette.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                    dialogContext, _parse(controller.text) ?? current),
                child: const Text('Готово'),
              ),
            ],
          );
        },
      );
      if (entered != null) _set(ref, entered);
    } finally {
      controller.dispose();
    }
  }

  static double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// Целые показываем без хвоста: «3», а не «3.0».
  static String _format(double value) =>
      value == value.truncateToDouble() ? value.toInt().toString() : '$value';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining =
        ref.watch(inventoryStateProvider.select(_remainingOf));
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: palette.surface.withValues(alpha: 0.75),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  product.inventoryUnit,
                  style: TextStyle(fontSize: 11, color: palette.textMuted),
                ),
              ],
            ),
          ),
          _QtyButton(
            icon: Icons.remove_rounded,
            tooltip: 'Убавить',
            onTap: remaining > 0 ? () => _set(ref, remaining - 1) : null,
          ),
          // Само число — тоже кнопка: открывает ручной ввод. Набрать «12»
          // быстрее, чем двенадцать раз нажать «плюс».
          Semantics(
            label: '${product.name}, остаток ${_format(remaining)}',
            button: true,
            child: InkWell(
              onTap: () => _showManualInput(context, ref, remaining),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                constraints: const BoxConstraints(
                    minWidth: 56, minHeight: kMinTapTarget),
                alignment: Alignment.center,
                child: Text(
                  _format(remaining),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            tooltip: 'Добавить',
            onTap: () => _set(ref, remaining + 1),
          ),
        ],
      ),
    );
  }
}

/// Кнопка «плюс» или «минус».
///
/// Видимый кружок остаётся небольшим, но область нажатия — не меньше
/// [kMinTapTarget]: в зале нажимают на бегу и часто мокрым пальцем.
class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: kMinTapTarget,
          height: kMinTapTarget,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled ? palette.textPrimary : palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
