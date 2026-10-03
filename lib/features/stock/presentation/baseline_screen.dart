/// Стартовые остатки: последняя полная инвентаризация уже работающего
/// заведения. С этого момента приложение начинает считать учёт.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/presentation/stock_widgets.dart';

class BaselineScreen extends ConsumerStatefulWidget {
  const BaselineScreen({super.key});

  @override
  ConsumerState<BaselineScreen> createState() => _BaselineScreenState();
}

class _BaselineScreenState extends ConsumerState<BaselineScreen> {
  final Map<String, TextEditingController> _ctrls = {};
  String _query = '';
  bool _saving = false;

  TextEditingController _ctrl(String id) =>
      _ctrls.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> get _values => {
        for (final e in _ctrls.entries)
          if (parseQty(e.value.text) != null) e.key: parseQty(e.value.text)!,
      };

  Future<void> _save() async {
    final values = _values;
    if (values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Введите остаток хотя бы по одному товару')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сохранить стартовые остатки?'),
        content: Text(
          'Товаров: ${values.length}. С этого момента приложение считает '
          'остаток = стартовые остатки + приход − списания − расход. '
          'Пустые поля не трогаются.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Сохранить')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    await ref.read(stockRepositoryProvider).recordCount(values,
        baseline: true, actor: Actor.of(ref.read(authRepositoryProvider)));
    ref.read(stockLevelsRepositoryProvider.notifier).updateLevels(values);
    ref.read(stockRevisionProvider.notifier).state++;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Стартовые остатки сохранены: ${values.length}')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final settings = ref.watch(settingsRepositoryProvider);
    final levels = ref.watch(stockLevelsRepositoryProvider);
    final catName = {for (final c in settings.categories) c.id: c.name};
    final q = _query.trim().toLowerCase();
    final products = settings.products
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final c = (catName[a.categoryId] ?? '')
            .compareTo(catName[b.categoryId] ?? '');
        return c != 0 ? c : a.name.compareTo(b.name);
      });

    return StockScaffold(
      title: 'Стартовые остатки',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: StockPrimaryButton(
            label: _saving ? 'Сохраняю…' : 'Сохранить (${_values.length})',
            icon: Icons.save_rounded,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
      body: settings.products.isEmpty
          ? const StockEmpty(
              icon: Icons.inventory_2_outlined,
              title: 'В каталоге нет товаров',
              subtitle:
                  'Добавьте товары в Настройках или импортируйте из iiko.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Перенесите сюда последнюю полную инвентаризацию — '
                  'в единицах инвентаризации. Приложение начнёт считать '
                  'приход, списания и расход с этого момента.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Поиск товара',
                  ),
                ),
                const SizedBox(height: 12),
                for (final (i, p) in products.indexed) ...[
                  if (i == 0 || products[i - 1].categoryId != p.categoryId)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                      child: Text(catName[p.categoryId] ?? 'Без категории',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(children: [
                        Expanded(
                          child:
                              Text(p.name, style: TextStyle(color: textColor)),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _ctrl(p.id),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]')),
                            ],
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: levels[p.id] == null
                                  ? '—'
                                  : fmtQty(levels[p.id]!),
                              suffixText: p.inventoryUnit,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
