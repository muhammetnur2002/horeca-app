import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/supply/data/gigachat_client.dart';
import 'package:horeca_app/features/supply/data/supply_repository.dart';
import 'package:horeca_app/features/supply/domain/ocr_quota.dart';
import 'package:horeca_app/features/supply/domain/supply_models.dart';
import 'package:horeca_app/features/supply/presentation/stock_levels_bridge.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _DraftLine {
  final name = TextEditingController();
  final qty = TextEditingController();
  final unit = TextEditingController(text: 'шт');

  _DraftLine({String? nameText, String? qtyText, String? unitText}) {
    if (nameText != null) name.text = nameText;
    if (qtyText != null) qty.text = qtyText;
    if (unitText != null && unitText.isNotEmpty) unit.text = unitText;
  }

  void dispose() {
    name.dispose();
    qty.dispose();
    unit.dispose();
  }
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final List<_DraftLine> _lines = [];
  bool _busy = false;
  bool _fromAi = false;
  String? _notice;

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine([SupplyLine? seed]) {
    setState(() {
      _lines.add(_DraftLine(
        nameText: seed?.name,
        qtyText: seed == null ? null : _fmt(seed.quantity),
        unitText: seed?.unit,
      ));
    });
  }

  Future<void> _recognize(ImageSource source) async {
    final key = await SupplyRepository.readGigaChatKey();
    if (!mounted) return;
    if (key == null) {
      setState(() => _notice = 'Ключ GigaChat не задан. Введите накладную вручную. Ключ лежит в Настройках.');
      return;
    }
    final quota = ref.read(supplyRepositoryProvider).quota;
    final today = OcrQuota.fromJson(quota.toJson(), DateTime.now());
    if (!today.canRecognize) {
      setState(() => _notice = 'Сегодня уже ${OcrQuota.dailyLimit} распознаваний. Дальше только вручную.');
      return;
    }
    final shot = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (shot == null || !mounted) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final bytes = await shot.readAsBytes();
      final parsed = await GigaChatClient().recognizeInvoice(
        authorizationKey: key,
        imageBytes: bytes,
        fileName: shot.name,
      );
      if (!ref.read(supplyRepositoryProvider.notifier).consumeRecognition()) {
        setState(() => _notice = 'Лимит распознаваний на сегодня закончился.');
        return;
      }
      if (!mounted) return;
      setState(() {
        for (final line in _lines) {
          line.dispose();
        }
        _lines
          ..clear()
          ..addAll(parsed.map((line) => _DraftLine(
                nameText: line.name,
                qtyText: _fmt(line.quantity),
                unitText: line.unit,
              )));
        _fromAi = true;
        _notice = 'Проверьте таблицу и поправьте, если модель ошиблась.';
      });
    } on GigaChatException catch (error) {
      if (mounted) setState(() => _notice = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Распознать не вышло. Введите строки вручную.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save(SupplyRequest? request) {
    final arrived = <SupplyLine>[];
    for (final line in _lines) {
      final qty = double.tryParse(line.qty.text.replaceAll(',', '.')) ?? 0;
      arrived.add(SupplyLine(
        name: line.name.text.trim(),
        quantity: qty,
        unit: line.unit.text.trim().isEmpty ? 'шт' : line.unit.text.trim(),
      ));
    }
    final ordered = request?.lines ?? const <SupplyLine>[];
    final matched = matchDelivery(ordered: ordered, arrived: arrived);
    if (matched.isEmpty) {
      setState(() => _notice = 'Добавьте строки накладной или сначала сохраните заявку.');
      return;
    }
    final products = ref.read(settingsRepositoryProvider).products;
    final resolved = [
      for (final line in matched)
        ReceiptLine(
          productId: stockKeyFor(products, line.name, productId: line.productId),
          name: line.name,
          unit: line.unit,
          orderedQty: line.orderedQty,
          receivedQty: line.receivedQty,
          status: line.status,
        ),
    ];
    ref.read(supplyRepositoryProvider.notifier).saveReceipt(GoodsReceipt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          requestId: request?.id,
          createdAt: DateTime.now(),
          source: _fromAi ? 'gigachat' : 'manual',
          lines: resolved,
        ));
    applyComputedStock(ref);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Приёмка сохранена. Приход записан в остаток.'),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final snapshot = ref.watch(supplyRepositoryProvider);
    final request = pickRequestToReceive(snapshot.requests, DateTime.now());
    final previous = receiptForRequest(snapshot.receipts, request?.id);
    final arrived = <SupplyLine>[];
    for (final line in _lines) {
      arrived.add(SupplyLine(
        name: line.name.text,
        quantity: double.tryParse(line.qty.text.replaceAll(',', '.')) ?? 0,
        unit: line.unit.text,
      ));
    }
    final preview = matchDelivery(
      ordered: request?.lines ?? const [],
      arrived: arrived,
    );
    final quota = OcrQuota.fromJson(snapshot.quota.toJson(), DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Приёмка'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppMetrics.screen, 8, AppMetrics.screen, 32),
        children: [
          _RequestCard(request: request, previous: previous, isDark: isDark, textColor: textColor),
          const SizedBox(height: AppMetrics.gap),
          Text(
            quota.canRecognize
                ? 'Распознаваний сегодня: ${quota.left} из ${OcrQuota.dailyLimit}. Без фото накладную можно ввести руками.'
                : 'Лимит ${OcrQuota.dailyLimit} фото на сегодня выбран. Ввод руками открыт.',
            style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
          ),
          const SizedBox(height: AppMetrics.gap),
          Row(children: [
            Expanded(child: _QuietButton(
              icon: Icons.photo_camera_outlined,
              label: 'Камера',
              onTap: _busy || !quota.canRecognize ? null : () => _recognize(ImageSource.camera),
            )),
            const SizedBox(width: 8),
            Expanded(child: _QuietButton(
              icon: Icons.photo_outlined,
              label: 'Файл',
              onTap: _busy || !quota.canRecognize ? null : () => _recognize(ImageSource.gallery),
            )),
            const SizedBox(width: 8),
            Expanded(child: _QuietButton(
              icon: Icons.add,
              label: 'Строка',
              onTap: _busy ? null : () => _addLine(),
            )),
          ]),
          if (_busy) ...[
            const SizedBox(height: AppMetrics.gap),
            const LinearProgressIndicator(color: AppColors.orange),
          ],
          if (_notice != null) ...[
            const SizedBox(height: AppMetrics.gap),
            Text(_notice!, style: TextStyle(fontSize: 13, height: 1.35, color: textColor)),
          ],
          const SizedBox(height: 16),
          Text('Накладная', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 4),
          const Text('Поправьте названия и количества до сохранения.',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: AppMetrics.gap),
          if (_lines.isEmpty)
            const Text('Строк пока нет.', style: TextStyle(fontSize: 13, color: AppColors.muted))
          else
            for (var i = 0; i < _lines.length; i++)
              _LineEditor(
                line: _lines[i],
                isDark: isDark,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() {
                  _lines.removeAt(i).dispose();
                }),
              ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Сверка', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: AppMetrics.gap),
            for (final line in preview) _StatusRow(line: line, textColor: textColor, isDark: isDark),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : () => _save(request),
            child: const Text('Сохранить приёмку'),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final SupplyRequest? request;
  final GoodsReceipt? previous;
  final bool isDark;
  final Color textColor;
  const _RequestCard({
    required this.request,
    required this.previous,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final title = request == null ? 'Заявки для сверки нет' : _title(request!.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.radius),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.7),
        border: Border.all(color: AppColors.orange.withOpacity(0.28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        Text(
          request == null
              ? 'Приход всё равно запишется. Сверка с заказом появится, когда заявка будет сохранена.'
              : '${request!.lines.length} поз. ${request!.departmentLabel}'.trim(),
          style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.muted),
        ),
        if (previous != null) ...[
          const SizedBox(height: 6),
          const Text(
            'По этой заявке приёмка уже была. Новая запись добавит приход ещё раз.',
            style: TextStyle(fontSize: 13, height: 1.35, color: AppColors.markLow),
          ),
        ],
      ]),
    );
  }

  String _title(DateTime created) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (!created.isBefore(yesterday) && created.isBefore(today)) return 'Вчерашняя заявка';
    if (!created.isBefore(today)) return 'Заявка сегодня';
    return 'Заявка от ${created.day}.${created.month}';
  }
}

class _LineEditor extends StatelessWidget {
  final _DraftLine line;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  const _LineEditor({
    required this.line,
    required this.isDark,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: TextField(
            controller: line.name,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(hintText: 'Товар', isDense: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: line.qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: '0', isDense: true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: line.unit,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(hintText: 'шт', isDense: true),
          ),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close, size: 18)),
      ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final ReceiptLine line;
  final Color textColor;
  final bool isDark;
  const _StatusRow({required this.line, required this.textColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = switch (line.status) {
      ReceiptStatus.matched => AppColors.markHigh,
      ReceiptStatus.short => AppColors.markLow,
      ReceiptStatus.missing => AppColors.markBad,
      ReceiptStatus.extra => AppColors.orange,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.radius),
        color: color.withOpacity(isDark ? 0.16 : 0.12),
      ),
      child: Row(children: [
        Expanded(child: Text(line.name, style: TextStyle(fontSize: 14, color: textColor))),
        Text(
          '${_fmt(line.receivedQty)} / ${_fmt(line.orderedQty)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(width: 8),
        Text(receiptStatusLabel(line.status), style: TextStyle(fontSize: 13, color: color)),
      ]),
    );
  }
}

class _QuietButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuietButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.orange,
        side: BorderSide(color: AppColors.orange.withOpacity(0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
