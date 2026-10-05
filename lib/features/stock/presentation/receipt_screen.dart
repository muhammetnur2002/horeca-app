/// Приёмка поставки: выбор заявки, таблица «что пришло» (строки из заявки,
/// распознанные с фото накладной/чека через Gemini или введённые вручную),
/// фото документа и отчёт «что пришло / не пришло».
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/core/db/app_database.dart';
import 'package:horeca_app/core/db/ids.dart';
import 'package:horeca_app/core/money.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/inventory/data/stock_levels_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository_products.dart';
import 'package:horeca_app/features/settings/presentation/gemini_settings_screen.dart';
import 'package:horeca_app/features/stock/data/gemini_invoice_service.dart';
import 'package:horeca_app/features/stock/data/stock_repository.dart';
import 'package:horeca_app/features/stock/domain/product_matcher.dart';
import 'package:horeca_app/features/stock/domain/receipt_report.dart';
import 'package:horeca_app/features/stock/domain/recognized_document.dart';
import 'package:horeca_app/features/stock/presentation/product_picker.dart';
import 'package:horeca_app/features/stock/presentation/stock_widgets.dart';
import 'package:horeca_app/shared/models/product_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Заявки, по которым можно принять поставку (с сохранёнными строками).
final _requestsProvider = FutureProvider.autoDispose<List<HistoryEntryRow>>(
    (ref) => ref.watch(stockRepositoryProvider).documents('request'));

/// Откуда взялась строка таблицы.
enum _Source { request, scan, manual }

class _EditLine {
  /// Товар каталога; null — строка ещё не сопоставлена с каталогом.
  String? productId;
  final TextEditingController name;
  String unit;
  String inventoryUnit;
  double factor;
  final double? ordered;
  final _Source source;
  final TextEditingController qty;
  final TextEditingController price;

  _EditLine({
    required this.productId,
    required String name,
    required this.unit,
    required this.inventoryUnit,
    required this.factor,
    required this.ordered,
    required this.source,
    double? quantity,
    double? price,
  })  : name = TextEditingController(text: name),
        qty = TextEditingController(
            text: (quantity ?? ordered) == null ? '' : fmtQty((quantity ?? ordered)!)),
        price = TextEditingController(text: price == null ? '' : fmtQty(_round2(price)));

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  double get received => parseQty(qty.text) ?? 0;
  double? get unitPrice => parseQty(price.text);

  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  /// null — ещё не выбрано; '' — приёмка без заявки.
  String? _requestId;
  String? _requestTitle;
  final List<_EditLine> _lines = [];
  String? _photoPath;
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  bool _scanning = false;

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> get _catalog => ref.read(settingsRepositoryProvider).products;

  ProductModel? _product(String? id) {
    if (id == null) return null;
    for (final p in _catalog) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _selectRequest(HistoryEntryRow? request) async {
    // Каталог нужен для единиц и коэффициентов — дожидаемся его загрузки,
    // иначе коэффициент «коробка → шт» молча стал бы 1.
    await ref.read(settingsRepositoryProvider.notifier).ready;
    final lines = request == null
        ? <DocumentLineRow>[]
        : await ref.read(stockRepositoryProvider).lines(request.id);
    if (!mounted) return;
    setState(() {
      _requestId = request?.id ?? '';
      _requestTitle = request?.title;
      for (final l in _lines) {
        l.dispose();
      }
      _lines
        ..clear()
        ..addAll([
          for (final l in lines)
            if (l.productId != null)
              _EditLine(
                productId: l.productId!,
                name: l.productName,
                unit: l.unit,
                inventoryUnit: _product(l.productId)?.inventoryUnit ?? l.unit,
                factor: _product(l.productId)?.unitFactor ?? 1,
                ordered: l.ordered ?? l.quantity,
                source: _Source.request,
              ),
        ]);
    });
  }

  // ── Добавление строк ──────────────────────────────────────────────────────

  Future<void> _addFromCatalog() async {
    final picked = await pickProduct(context, ref,
        exclude: _lines.map((l) => l.productId).whereType<String>().toSet());
    if (picked == null || !mounted) return;
    setState(() => _lines.add(_EditLine(
          productId: picked.id,
          name: picked.name,
          unit: picked.unit,
          inventoryUnit: picked.inventoryUnit,
          factor: picked.unitFactor,
          ordered: null,
          source: _Source.manual,
        )));
  }

  /// Пустая строка ручного ввода: название, количество, единица, цена.
  void _addManualRow() {
    setState(() => _lines.add(_EditLine(
          productId: null,
          name: '',
          unit: 'шт',
          inventoryUnit: 'шт',
          factor: 1,
          ordered: null,
          source: _Source.manual,
        )));
  }

  Future<void> _linkToCatalog(_EditLine line) async {
    final picked = await pickProduct(context, ref);
    if (picked == null || !mounted) return;
    setState(() {
      line.productId = picked.id;
      line.name.text = picked.name;
      line.unit = picked.unit;
      line.inventoryUnit = picked.inventoryUnit;
      line.factor = picked.unitFactor;
    });
  }

  // ── Фото и распознавание ──────────────────────────────────────────────────

  Future<String?> _takePhoto(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, imageQuality: 80, maxWidth: 2200);
      if (x == null || !mounted) return null;
      var path = x.path;
      if (!kIsWeb) {
        // Копируем в папку приложения: временный файл камеры может
        // исчезнуть, а накладная должна остаться при документе.
        final dir = Directory(
            '${(await getApplicationDocumentsDirectory()).path}/receipts');
        await dir.create(recursive: true);
        path = (await File(x.path).copy('${dir.path}/${Ids.newId()}.jpg')).path;
      }
      if (!mounted) return null;
      setState(() => _photoPath = path);
      return path;
    } catch (e) {
      if (mounted) _snack('Не удалось получить фото: $e');
      return null;
    }
  }

  Future<ImageSource?> _askSource() => showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сфотографировать'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ]),
        ),
      );

  /// Фото накладной или чека → Gemini → строки таблицы.
  Future<void> _scan() async {
    final service = ref.read(geminiInvoiceServiceProvider);
    if (!await service.hasKey()) {
      if (!mounted) return;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Нужен ключ Gemini'),
          content: const Text(
              'Чтобы распознавать накладные и чеки, укажите ключ Gemini API '
              'в настройках. Это бесплатно для небольшого объёма.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Позже')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Открыть настройки')),
          ],
        ),
      );
      if (open == true && mounted) {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GeminiSettingsScreen()));
      }
      return;
    }
    final source = await _askSource();
    if (source == null) return;
    final path = await _takePhoto(source);
    if (path == null || kIsWeb) return;

    setState(() => _scanning = true);
    try {
      final doc = await service.recognize(await File(path).readAsBytes());
      if (!mounted) return;
      _applyRecognition(doc);
    } on GeminiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _applyRecognition(RecognizedDocument doc) {
    var matched = 0, added = 0;
    setState(() {
      for (final item in doc.items) {
        final product = ProductMatcher.bestMatch<ProductModel>(
            item.name, _catalog, (p) => p.name);
        // Строка этой заявки (или уже добавленная) с тем же товаром —
        // проставляем ей количество, а не дублируем.
        final existing = product == null
            ? null
            : _lines.where((l) => l.productId == product.id).firstOrNull;
        if (existing != null) {
          existing.qty.text = fmtQty(item.quantity);
          if (item.unitPrice != null) {
            existing.price.text = fmtQty(_EditLine._round2(item.unitPrice!));
          }
          matched++;
          continue;
        }
        _lines.add(_EditLine(
          productId: product?.id,
          name: product?.name ?? item.name,
          unit: product?.unit ?? item.unit ?? 'шт',
          inventoryUnit: product?.inventoryUnit ?? item.unit ?? 'шт',
          factor: product?.unitFactor ?? 1,
          ordered: null,
          source: _Source.scan,
          quantity: item.quantity,
          price: item.unitPrice,
        ));
        product == null ? added++ : matched++;
      }
      if (_noteCtrl.text.trim().isEmpty) {
        _noteCtrl.text = [
          if (doc.supplier != null) 'Поставщик: ${doc.supplier}',
          if (doc.number != null) '${doc.kind} № ${doc.number}',
          if (doc.date != null) 'от ${doc.date}',
        ].join(', ');
      }
    });
    _snack(doc.items.isEmpty
        ? 'Товарных строк не нашлось — проверьте фото или добавьте строки вручную'
        : 'Распознано строк: ${doc.items.length}. С каталогом сопоставлено: $matched'
            '${added > 0 ? ', без товара: $added — выберите их' : ''}.');
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // ── Сохранение ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final lines = [
      for (final l in _lines)
        if (l.name.text.trim().isNotEmpty || l.productId != null)
          ReceiptLine(
            productId: l.productId,
            productName: l.name.text.trim().isEmpty
                ? (_product(l.productId)?.name ?? 'Без названия')
                : l.name.text.trim(),
            unit: l.unit,
            unitFactor: l.factor,
            ordered: l.ordered,
            received: l.received,
            price: l.unitPrice,
          ),
    ];
    if (lines.every((l) => l.received <= 0 && l.ordered == null)) {
      _snack('Отметьте, сколько пришло, хотя бы по одному товару');
      return;
    }
    final unmatched = lines.where((l) => l.productId == null && l.received > 0);
    if (unmatched.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Есть строки без товара'),
          content: Text(
              '${unmatched.map((l) => l.productName).take(3).join(', ')}'
              '${unmatched.length > 3 ? '…' : ''} — не выбраны в каталоге. '
              'Они попадут в отчёт приёмки, но не в остатки.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Выбрать товары')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Сохранить так')),
          ],
        ),
      );
      if (go != true) return;
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
      currency: settings.currency,
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
        if (l.received > 0 && l.productId != null)
          l.productId!: l.received * l.unitFactor,
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

  // ── Вёрстка ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Держим каталог загруженным, пока открыт экран.
    ref.watch(settingsRepositoryProvider);
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
                  onPressed: _saving || _scanning ? null : _save,
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
          'Строки заявки подставятся сами — останется отметить, сколько '
          'пришло, или распознать накладную по фото. Заявки сохраняются при '
          'нажатии «PDF».',
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
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.muted),
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
    final currency = ref.watch(settingsRepositoryProvider).currency;
    final total = _lines.fold<double>(0, (s, l) {
      final p = l.unitPrice;
      return p == null ? s : s + p * l.received;
    });
    final hasPrices = _lines.any((l) => l.unitPrice != null);

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
        // Как заполнить таблицу: фото → Gemini, вручную, из каталога.
        Row(children: [
          Expanded(
            child: _ToolButton(
              icon: Icons.document_scanner_outlined,
              label: _scanning ? 'Распознаю…' : 'Фото → строки',
              primary: true,
              onTap: _scanning ? null : _scan,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToolButton(
              icon: Icons.edit_note_rounded,
              label: 'Вручную',
              onTap: _addManualRow,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToolButton(
              icon: Icons.playlist_add_rounded,
              label: 'Из каталога',
              onTap: _addFromCatalog,
            ),
          ),
        ]),
        if (_scanning)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        const SizedBox(height: 12),
        if (_lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
                'Сфотографируйте накладную или чек — Gemini заполнит таблицу. '
                'Без накладной добавьте строки вручную.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          ),
        for (final l in _lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LineCard(
              line: l,
              textColor: textColor,
              currency: currency,
              onChanged: () => setState(() {}),
              onLink: () => _linkToCatalog(l),
              onFactor: (f) {
                setState(() => l.factor = f);
                if (l.productId != null) {
                  ref
                      .read(settingsRepositoryProvider.notifier)
                      .setProductUnitFactor(l.productId!, f);
                }
              },
              onRemove: l.source == _Source.request
                  ? null
                  : () => setState(() {
                        _lines.remove(l);
                        l.dispose();
                      }),
            ),
          ),
        if (hasPrices)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(children: [
              Text('Сумма по строкам',
                  style: TextStyle(color: AppColors.muted)),
              const Spacer(),
              Text('${formatMoney(total)} $currency',
                  style: TextStyle(
                      fontFamily: AppFonts.mono,
                      fontFamilyFallback: AppFonts.fallback,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
            ]),
          ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Накладная / чек',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 4),
              Text(
                _photoPath == null
                    ? 'Фото документа останется при приёмке. Для распознавания '
                        'оно отправляется в Google Gemini.'
                    : 'Фото сохранено при приёмке.',
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
                    label: Text(_photoPath == null
                        ? 'Только сфотографировать'
                        : 'Переснять'),
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
            hintText: 'Комментарий (поставщик, номер накладной…)',
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = primary ? Colors.white : (isDark ? Colors.white : AppColors.ink);
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: primary
                  ? LinearGradient(colors: [AppColors.orange, AppColors.green])
                  : null,
              color: primary
                  ? null
                  : Colors.white.withOpacity(isDark ? 0.07 : 0.65),
              border: primary
                  ? null
                  : Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.9)),
            ),
            child: Column(children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final _EditLine line;
  final Color textColor;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onLink;
  final ValueChanged<double> onFactor;
  final VoidCallback? onRemove;

  const _LineCard({
    required this.line,
    required this.textColor,
    required this.currency,
    required this.onChanged,
    required this.onLink,
    required this.onFactor,
    this.onRemove,
  });

  static const _units = ['шт', 'кг', 'гр', 'л', 'мл', 'уп', 'коробка', 'бут'];

  @override
  Widget build(BuildContext context) {
    final ordered = line.ordered;
    final received = line.received;
    final unlinked = line.productId == null;
    final Color status;
    if (unlinked) {
      status = AppColors.accent3;
    } else if (ordered == null) {
      status = AppColors.green;
    } else if (received <= 0) {
      status = Colors.redAccent;
    } else if (received < ordered) {
      status = Colors.amber;
    } else {
      status = AppColors.green;
    }
    final unitsDiffer = !unlinked && line.unit != line.inventoryUnit;
    final numberFormatter = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

    return GlassCard(
      borderColor: status.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: unlinked
                  ? TextField(
                      controller: line.name,
                      onChanged: (_) => onChanged(),
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: textColor),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Название товара',
                      ),
                    )
                  : Text(line.name.text,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: textColor)),
            ),
            if (onRemove != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.muted),
              ),
          ]),
          const SizedBox(height: 4),
          if (unlinked)
            Row(children: [
              Expanded(
                child: Text('Нет в каталоге — в остатки не попадёт',
                    style: TextStyle(fontSize: 12, color: AppColors.accent3)),
              ),
              TextButton(
                onPressed: onLink,
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
                child: const Text('Выбрать товар'),
              ),
            ])
          else
            Text(
              ordered == null
                  ? (line.source == _Source.scan
                      ? 'Распознано с фото'
                      : 'Не из заявки')
                  : 'Заказано: ${fmtQty(ordered)} ${line.unit}',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: line.qty,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: numberFormatter,
                onChanged: (_) => onChanged(),
                style: const TextStyle(fontFamily: AppFonts.mono),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Пришло',
                  suffixText: unlinked ? null : line.unit,
                ),
              ),
            ),
            if (unlinked) ...[
              const SizedBox(width: 6),
              DropdownButton<String>(
                value: _units.contains(line.unit) ? line.unit : 'шт',
                underline: const SizedBox(),
                items: [
                  for (final u in _units)
                    DropdownMenuItem(value: u, child: Text(u)),
                ],
                onChanged: (u) {
                  if (u == null) return;
                  line.unit = u;
                  line.inventoryUnit = u;
                  onChanged();
                },
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextField(
                controller: line.price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: numberFormatter,
                onChanged: (_) => onChanged(),
                style: const TextStyle(fontFamily: AppFonts.mono),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Цена',
                  suffixText: currency,
                ),
              ),
            ),
          ]),
          if (ordered != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              _Quick(
                label: 'Всё',
                color: AppColors.green,
                onTap: () {
                  line.qty.text = fmtQty(ordered);
                  onChanged();
                },
              ),
              const SizedBox(width: 6),
              _Quick(
                label: 'Нет',
                color: Colors.redAccent,
                onTap: () {
                  line.qty.text = '0';
                  onChanged();
                },
              ),
            ]),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
