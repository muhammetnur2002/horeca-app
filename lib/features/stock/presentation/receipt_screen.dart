/// Приёмка поставки: выбор заявки, отметка «сколько пришло» по каждой
/// строке, фото бумажной накладной и отчёт «что пришло / не пришло».
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_products.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/domain/receipt_report.dart';
import 'package:horeca_app/features/stock/presentation/product_picker.dart';
import 'package:horeca_app/features/stock/presentation/stock_widgets.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Заявки, по которым можно принять поставку (с сохранёнными строками).
final _requestsProvider = FutureProvider.autoDispose<List<HistoryEntryRow>>(
    (ref) => ref.watch(stockRepositoryProvider).documents('request'));

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _EditLine {
  final String productId;
  final String name;
  final String unit;
  final String inventoryUnit;
  double factor;
  final double? ordered;
  final TextEditingController ctrl;

  _EditLine({
    required this.productId,
    required this.name,
    required this.unit,
    required this.inventoryUnit,
    required this.factor,
    required this.ordered,
  }) : ctrl =
            TextEditingController(text: ordered == null ? '' : fmtQty(ordered));

  double get received => parseQty(ctrl.text) ?? 0;
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  /// null — ещё не выбрано; '' — приёмка без заявки.
  String? _requestId;
  String? _requestTitle;
  final List<_EditLine> _lines = [];
  String? _photoPath;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final l in _lines) {
      l.ctrl.dispose();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  ProductModel? _product(String id) {
    final list = ref.read(settingsRepositoryProvider).products;
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _selectRequest(HistoryEntryRow? request) async {
    final lines = request == null
        ? <DocumentLineRow>[]
        : await ref.read(stockRepositoryProvider).lines(request.id);
    if (!mounted) return;
    setState(() {
      _requestId = request?.id ?? '';
      _requestTitle = request?.title;
      _lines
        ..clear()
        ..addAll([
          for (final l in lines)
            if (l.productId != null)
              _EditLine(
                productId: l.productId!,
                name: l.productName,
                unit: l.unit,
                inventoryUnit: _product(l.productId!)?.inventoryUnit ?? l.unit,
                factor: _product(l.productId!)?.unitFactor ?? 1,
                ordered: l.ordered ?? l.quantity,
              ),
        ]);
    });
  }

  Future<void> _addProduct() async {
    final picked = await pickProduct(context, ref,
        exclude: _lines.map((l) => l.productId).toSet());
    if (picked == null || !mounted) return;
    setState(() => _lines.add(_EditLine(
          productId: picked.id,
          name: picked.name,
          unit: picked.unit,
          inventoryUnit: picked.inventoryUnit,
          factor: picked.unitFactor,
          ordered: null,
        )));
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, imageQuality: 70, maxWidth: 2000);
      if (x == null || !mounted) return;
      var path = x.path;
      if (!kIsWeb) {
        // Копируем в папку приложения: временный файл камеры может
        // исчезнуть, а накладная должна остаться при документе.
        final dir = Directory(
            '${(await getApplicationDocumentsDirectory()).path}/receipts');
        await dir.create(recursive: true);
        path = (await File(x.path).copy('${dir.path}/${Ids.newId()}.jpg')).path;
      }
      if (!mounted) return;
      setState(() => _photoPath = path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось получить фото: $e')));
    }
  }

  Future<void> _save() async {
    final lines = [
      for (final l in _lines)
        ReceiptLine(
          productId: l.productId,
          productName: l.name,
          unit: l.unit,
          unitFactor: l.factor,
          ordered: l.ordered,
          received: l.received,
        ),
    ];
    if (lines.every((l) => l.received <= 0 && l.ordered == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Отметьте, сколько пришло, хотя бы по одному товару')));
      return;
    }
    setState(() => _saving = true);
    final auth = ref.read(authRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    final text = buildReceiptReport(
      venueName: settings.establishmentName,
      at: now,
      lines: lines,
      requestTitle: _requestTitle,
      staffName: auth.userName,
      note: _noteCtrl.text,
    );
    await ref.read(stockRepositoryProvider).recordReceipt(
          lines: lines,
          title: _requestTitle == null
              ? 'Приёмка без заявки'
              : 'Приёмка: $_requestTitle',
          text: text,
          requestId: (_requestId ?? '').isEmpty ? null : _requestId,
          photoPath: _photoPath,
          actor: Actor.of(auth),
          at: now,
        );
    ref.read(stockLevelsRepositoryProvider.notifier).applyDeltas({
      for (final l in lines)
        if (l.received > 0) l.productId: l.received * l.unitFactor,
    });
    ref.read(stockRevisionProvider.notifier).state++;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Поставка принята'),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Share.share(text),
            child: const Text('Поделиться'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StockScaffold(
      title: 'Приёмка поставки',
      bottom: _requestId == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: StockPrimaryButton(
                  label: _saving ? 'Сохраняю…' : 'Принять поставку',
                  icon: Icons.check_rounded,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ),
      body: _requestId == null ? _buildPickRequest() : _buildLines(),
    );
  }

  Widget _buildPickRequest() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    final requests = ref.watch(_requestsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('По какой заявке пришла поставка?',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        Text(
          'Строки заявки подставятся сами — останется отметить, '
          'сколько пришло. Заявки сохраняются при нажатии «PDF».',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        ...switch (requests) {
          AsyncData(:final value) when value.isNotEmpty => [
              for (final r in value.take(30))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () => _selectRequest(r),
                    child: Row(children: [
                      Icon(Icons.assignment_outlined, color: AppColors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                            Text(fmtDate(r.createdAt.toLocal()),
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ]),
                  ),
                ),
            ],
          AsyncData() => [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('Сохранённых заявок пока нет.',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ],
          AsyncError(:final error) => [Text('Ошибка: $error')],
          _ => [const Center(child: CircularProgressIndicator())],
        },
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => _selectRequest(null),
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('Приёмка без заявки'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildLines() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_requestTitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_requestTitle!,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.muted)),
          ),
        if (_lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Добавьте товары, которые пришли.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          ),
        for (final l in _lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LineCard(
              line: l,
              textColor: textColor,
              onChanged: () => setState(() {}),
              onFactor: (f) {
                setState(() => l.factor = f);
                ref
                    .read(settingsRepositoryProvider.notifier)
                    .setProductUnitFactor(l.productId, f);
              },
              onRemove: l.ordered == null
                  ? () => setState(() {
                        _lines.remove(l);
                        l.ctrl.dispose();
                      })
                  : null,
            ),
          ),
        TextButton.icon(
          onPressed: _addProduct,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Добавить товар не из заявки'),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Накладная',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 4),
              Text(
                'Сфотографируйте бумажную накладную — фото останется '
                'при приёмке, его можно открыть в любой момент.',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              if (_photoPath != null && !kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_photoPath!),
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _takePhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                        _photoPath == null ? 'Сфотографировать' : 'Переснять'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Из галереи',
                  onPressed: () => _takePhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Комментарий (например: молоко с коротким сроком)',
          ),
        ),
      ],
    );
  }
}

class _LineCard extends StatelessWidget {
  final _EditLine line;
  final Color textColor;
  final VoidCallback onChanged;
  final ValueChanged<double> onFactor;
  final VoidCallback? onRemove;

  const _LineCard({
    required this.line,
    required this.textColor,
    required this.onChanged,
    required this.onFactor,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = line.ordered;
    final received = line.received;
    final Color status;
    if (ordered == null) {
      status = AppColors.green;
    } else if (received <= 0) {
      status = Colors.redAccent;
    } else if (received < ordered) {
      status = Colors.amber;
    } else {
      status = AppColors.green;
    }
    final unitsDiffer = line.unit != line.inventoryUnit;

    return GlassCard(
      borderColor: status.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(line.name,
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child:
                    Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
              ),
          ]),
          const SizedBox(height: 4),
          Text(
            ordered == null
                ? 'Не из заявки'
                : 'Заказано: ${fmtQty(ordered)} ${line.unit}',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: line.ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '0',
                  suffixText: line.unit,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (ordered != null) ...[
              _Quick(
                label: 'Всё',
                color: AppColors.green,
                onTap: () {
                  line.ctrl.text = fmtQty(ordered);
                  onChanged();
                },
              ),
              const SizedBox(width: 6),
              _Quick(
                label: 'Нет',
                color: Colors.redAccent,
                onTap: () {
                  line.ctrl.text = '0';
                  onChanged();
                },
              ),
            ],
          ]),
          if (unitsDiffer) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('1 ${line.unit} = ',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
              SizedBox(
                width: 64,
                child: TextFormField(
                  initialValue: fmtQty(line.factor),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (v) {
                    final f = parseQty(v);
                    if (f != null && f > 0) onFactor(f);
                  },
                ),
              ),
              Text(' ${line.inventoryUnit}',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Quick({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
