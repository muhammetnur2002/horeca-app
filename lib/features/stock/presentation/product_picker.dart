/// Выбор товара из каталога заведения с поиском.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/shared/models/product_model.dart';

Future<ProductModel?> pickProduct(
  BuildContext context,
  WidgetRef ref, {
  Set<String> exclude = const {},
}) {
  final products = ref
      .read(settingsRepositoryProvider)
      .products
      .where((p) => !exclude.contains(p.id))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return showModalBottomSheet<ProductModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkCard
        : Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _PickerSheet(products: products),
  );
}

class _PickerSheet extends StatefulWidget {
  final List<ProductModel> products;
  const _PickerSheet({required this.products});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.products
        : widget.products
            .where((p) => p.name.toLowerCase().contains(q))
            .toList();
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Поиск товара',
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('Ничего не найдено',
                          style: TextStyle(color: AppColors.muted)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(list[i].name),
                        subtitle: Text(list[i].unit),
                        onTap: () => Navigator.pop(context, list[i]),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}
