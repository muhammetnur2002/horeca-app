import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_pdf.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

enum WriteOffType { writeOff, spoilage }

class DessertItem {
  final String name;
  int showcase;
  int stock;
  int writeOff;
  WriteOffType writeOffType;
  DessertItem({required this.name, this.showcase=0, this.stock=0,
      this.writeOff=0, this.writeOffType=WriteOffType.writeOff});
}

class ManualWriteOff {
  String name;
  int quantity;
  String unit;
  WriteOffType type;
  ManualWriteOff({required this.name, this.quantity=1,
      this.unit='шт', this.type=WriteOffType.writeOff});
}

class ShiftCloseScreen extends ConsumerStatefulWidget {
  const ShiftCloseScreen({super.key});
  @override
  ConsumerState<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends ConsumerState<ShiftCloseScreen> {
  int _step = 0;
  final int _totalSteps = 4;
  final Set<String> _selectedStaff = {};
  List<DessertItem> _desserts = [];
  bool _dessertsLoaded = false;
  final List<ManualWriteOff> _manualWriteOffs = [];

  final _qrCtrl     = TextEditingController(text: '0');
  final _cardCtrl   = TextEditingController(text: '0');
  final _cashCtrl   = TextEditingController(text: '0');
  final _manualCtrl = TextEditingController();
  final _morningCashCtrl = TextEditingController(text: '0');
  final _eveningCashCtrl = TextEditingController(text: '0');
  final _inkassCtrl = TextEditingController(text: '0');
  bool _hasInkass = false;

  double get _autoTotal =>
      (double.tryParse(_qrCtrl.text) ?? 0) +
      (double.tryParse(_cardCtrl.text) ?? 0) +
      (double.tryParse(_cashCtrl.text) ?? 0);
  double get _finalTotal => double.tryParse(_manualCtrl.text) ?? _autoTotal;
  double get _tomorrowCash {
    final e = double.tryParse(_eveningCashCtrl.text) ?? 0;
    final i = _hasInkass ? (double.tryParse(_inkassCtrl.text) ?? 0) : 0;
    return e - i;
  }

  @override
  void dispose() {
    _qrCtrl.dispose(); _cardCtrl.dispose(); _cashCtrl.dispose();
    _manualCtrl.dispose(); _morningCashCtrl.dispose();
    _eveningCashCtrl.dispose(); _inkassCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) setState(() => _step++);
    else _onSubmit();
  }
  void _back() { if (_step > 0) setState(() => _step--); }

  void _onSubmit() async {
    final confirm = await showDialog<bool>(
      context: context, builder: (_) => _ConfirmDialog());
    if (confirm == true && mounted) {
      await ShiftClosePdf.generateAndShare(
        currency: ref.read(settingsRepositoryProvider).currency,
        context: context,
        staffName: _selectedStaff.isEmpty ? '—' : _selectedStaff.join(', '),
        desserts: _desserts,
        qr: double.tryParse(_qrCtrl.text) ?? 0,
        card: double.tryParse(_cardCtrl.text) ?? 0,
        cash: double.tryParse(_cashCtrl.text) ?? 0,
        totalRevenue: _finalTotal,
        morningCash: double.tryParse(_morningCashCtrl.text) ?? 0,
        eveningCash: double.tryParse(_eveningCashCtrl.text) ?? 0,
        inkass: _hasInkass ? (double.tryParse(_inkassCtrl.text) ?? 0) : 0,
        tomorrowCash: _tomorrowCash,
        date: DateTime.now(),
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _addManualWriteOff(bool isDark) {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'шт');
    WriteOffType type = WriteOffType.writeOff;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ручное списание',
              style: TextStyle(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Продукт, заготовка...',
                    prefixIcon: Icon(Icons.edit_outlined, color: AppColors.orange))),
              const SizedBox(height: 12),
              TextField(controller: unitCtrl,
                  decoration: const InputDecoration(
                    hintText: 'шт, кг, л...',
                    prefixIcon: Icon(Icons.straighten_rounded, color: AppColors.orange))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setS(() => type = WriteOffType.writeOff),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: type == WriteOffType.writeOff
                          ? AppColors.orange.withOpacity(0.15) : Colors.transparent,
                      border: Border.all(color: type == WriteOffType.writeOff
                          ? AppColors.orange : AppColors.muted.withOpacity(0.3))),
                    child: const Text('📦 Списание',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.orange))))),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => setS(() => type = WriteOffType.spoilage),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: type == WriteOffType.spoilage
                          ? Colors.redAccent.withOpacity(0.15) : Colors.transparent,
                      border: Border.all(color: type == WriteOffType.spoilage
                          ? Colors.redAccent : AppColors.muted.withOpacity(0.3))),
                    child: const Text('🗑 Порча',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.redAccent))))),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена', style: TextStyle(color: AppColors.muted))),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() => _manualWriteOffs.add(ManualWriteOff(
                    name: nameCtrl.text.trim(),
                    unit: unitCtrl.text.trim().isEmpty ? 'шт' : unitCtrl.text.trim(),
                    type: type)));
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Добавить')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(settingsRepositoryProvider).currency;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.of(context).pop()),
        title: Text('Закрытие смены', style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [Padding(padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(_formattedDate(),
                style: const TextStyle(fontSize: 12, color: AppColors.muted))))],
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(child: Column(children: [
          const SizedBox(height: 8),
          _buildStepper(isDark),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCurrentStep(isDark, currency))),
          _buildBottomBar(isDark),
        ])),
      ]),
    );
  }

  Widget _buildStepper(bool isDark) {
    final labels = ['Смена', 'Оплата', 'Касса', 'Итог'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: List.generate(_totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(child: Container(height: 2,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(1),
                  color: (i ~/ 2) < _step
                      ? AppColors.orange
                      : Colors.white.withOpacity(isDark ? 0.1 : 0.0))));
        }
        final di = i ~/ 2;
        final isDone = di < _step; final isActive = di == _step;
        return GestureDetector(
          onTap: () { if (di <= _step) setState(() => _step = di); },
          child: Column(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 250),
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: isDone ? AppColors.green.withOpacity(0.2)
                    : isActive ? AppColors.orange
                    : Colors.white.withOpacity(isDark ? 0.08 : 0.4),
                border: Border.all(
                  color: isDone ? AppColors.green
                      : isActive ? AppColors.orange
                      : Colors.white.withOpacity(0.15), width: 1.5)),
              child: Center(child: isDone
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.green)
                  : Text('${di + 1}', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.muted)))),
            const SizedBox(height: 4),
            Text(labels[di], style: TextStyle(fontSize: 10,
                color: isActive ? AppColors.orange : AppColors.muted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ]),
        );
      })),
    );
  }

  Widget _buildCurrentStep(bool isDark, String currency) {
    switch (_step) {
      case 0: return _buildStep1(isDark);
      case 1: return _buildStep2(isDark, currency);
      case 2: return _buildStep3(isDark, currency);
      case 3: return _buildStep4(isDark, currency);
      default: return const SizedBox();
    }
  }

  Widget _buildStep1(bool isDark) {
    final staffList = ref.watch(settingsRepositoryProvider).staff;
    final settings = ref.read(settingsRepositoryProvider);
    if (!_dessertsLoaded) {
      final catIds = settings.categories
          .where((c) => c.name.toLowerCase().contains('десерт'))
          .map((c) => c.id).toSet();
      final prods = settings.products
          .where((p) => catIds.contains(p.categoryId)).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          _desserts = prods.map((p) => DessertItem(name: p.name)).toList();
          _dessertsLoaded = true;
        });
      });
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      _StepHeader(step: 1, total: _totalSteps, title: 'Смена и десерты'),
      const SizedBox(height: 16),

      // Сотрудники
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(text: 'Кто работал в смену'),
        const SizedBox(height: 10),
        staffList.isEmpty
            ? Text('Добавьте сотрудников в Настройки → Смена',
                style: TextStyle(fontSize: 13, color: AppColors.muted))
            : Wrap(spacing: 8, runSpacing: 8,
                children: staffList.map((name) {
                  final sel = _selectedStaff.contains(name);
                  return GestureDetector(
                    onTap: () => setState(() =>
                        sel ? _selectedStaff.remove(name) : _selectedStaff.add(name)),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                        color: sel ? AppColors.orange.withOpacity(0.15)
                            : Colors.white.withOpacity(isDark ? 0.06 : 0.5),
                        border: Border.all(color: sel
                            ? AppColors.orange.withOpacity(0.5)
                            : Colors.white.withOpacity(0.15))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (sel) const Padding(padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_rounded, size: 14, color: AppColors.orange)),
                        Text(name, style: TextStyle(fontSize: 13,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? AppColors.orange : AppColors.muted)),
                      ])));
                }).toList()),
      ])),

      const SizedBox(height: 10),

      // Витрина
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(text: 'Десерты — витрина'),
        const SizedBox(height: 10),
        _desserts.isEmpty
            ? Text('Добавьте товары в категорию "Десерты"',
                style: TextStyle(fontSize: 13, color: AppColors.muted))
            : Column(children: _desserts.map((d) => _DessertRow(
                name: d.name, value: d.showcase,
                onChanged: (v) => setState(() => d.showcase = v),
                isDark: isDark)).toList()),
      ])),

      const SizedBox(height: 10),

      // Склад
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(text: 'Десерты — склад'),
        const SizedBox(height: 10),
        _desserts.isEmpty
            ? Text('Добавьте товары в категорию "Десерты"',
                style: TextStyle(fontSize: 13, color: AppColors.muted))
            : Column(children: _desserts.map((d) => _DessertRow(
                name: d.name, value: d.stock,
                onChanged: (v) => setState(() => d.stock = v),
                isDark: isDark)).toList()),
      ])),

      const SizedBox(height: 10),

      // Списания/порча десертов
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(text: 'Списания / порча — десерты'),
        const SizedBox(height: 10),
        _desserts.isEmpty
            ? Text('Добавьте товары в категорию "Десерты"',
                style: TextStyle(fontSize: 13, color: AppColors.muted))
            : Column(children: _desserts.map((d) => Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DessertRow(name: d.name, value: d.writeOff,
                  onChanged: (v) => setState(() => d.writeOff = v),
                  isDark: isDark, isWriteOff: true),
              if (d.writeOff > 0) Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Row(children: [
                  _TypeChip(label: '📦 Списание',
                      selected: d.writeOffType == WriteOffType.writeOff,
                      onTap: () => setState(() => d.writeOffType = WriteOffType.writeOff),
                      isDark: isDark),
                  const SizedBox(width: 8),
                  _TypeChip(label: '🗑 Порча',
                      selected: d.writeOffType == WriteOffType.spoilage,
                      onTap: () => setState(() => d.writeOffType = WriteOffType.spoilage),
                      isDark: isDark, isRed: true),
                ])),
            ])).toList()),
      ])),

      const SizedBox(height: 10),

      // Ручные списания
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _CardLabel(text: 'Ручные списания'),
          GestureDetector(
            onTap: () => _addManualWriteOff(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.orange.withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.orange),
                SizedBox(width: 4),
                Text('Добавить', style: TextStyle(fontSize: 12,
                    color: AppColors.orange, fontWeight: FontWeight.w600)),
              ]))),
        ]),
        if (_manualWriteOffs.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 10),
              child: Text('Нажмите + чтобы добавить списание вручную',
                  style: TextStyle(fontSize: 13, color: AppColors.muted))),
        ..._manualWriteOffs.asMap().entries.map((e) {
          final i = e.key; final m = e.value;
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(m.name, style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                GestureDetector(onTap: () => setState(() => _manualWriteOffs.removeAt(i)),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _QtyBtn(icon: Icons.remove, isDark: isDark,
                    onTap: () { if (m.quantity > 1) setState(() => m.quantity--); }),
                SizedBox(width: 36, child: Text('${m.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
                _QtyBtn(icon: Icons.add, isDark: isDark,
                    onTap: () => setState(() => m.quantity++)),
                const SizedBox(width: 8),
                Text(m.unit, style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const Spacer(),
                _TypeChip(label: '📦 Списание',
                    selected: m.type == WriteOffType.writeOff,
                    onTap: () => setState(() => m.type = WriteOffType.writeOff),
                    isDark: isDark),
                const SizedBox(width: 6),
                _TypeChip(label: '🗑 Порча',
                    selected: m.type == WriteOffType.spoilage,
                    onTap: () => setState(() => m.type = WriteOffType.spoilage),
                    isDark: isDark, isRed: true),
              ]),
            ]),
          );
        }),
      ])),

      const SizedBox(height: 16),
    ]);
  }

  Widget _buildStep2(bool isDark, String currency) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      _StepHeader(step: 2, total: _totalSteps, title: 'Способы оплаты'),
      const SizedBox(height: 16),
      _PaymentRow(icon: Icons.qr_code_rounded, label: 'QR-код',
          hint: 'СБП', controller: _qrCtrl,
          color: AppColors.green, isDark: isDark, currency: currency,
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 10),
      _PaymentRow(icon: Icons.credit_card_rounded, label: 'Банковская карта',
          hint: 'Сбербанк', controller: _cardCtrl,
          color: const Color(0xFF378ADD), isDark: isDark, currency: currency,
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 10),
      _PaymentRow(icon: Icons.payments_outlined, label: 'Наличные',
          hint: 'Принято за смену', controller: _cashCtrl,
          color: AppColors.orange, isDark: isDark, currency: currency,
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 16),
      _GlassCard(isDark: isDark, accentColor: AppColors.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Итоговая выручка (авто)',
            style: TextStyle(fontSize: 11, color: AppColors.green)),
        const SizedBox(height: 4),
        Text('${_formatMoney(_autoTotal)} $currency',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                color: AppColors.green)),
        const SizedBox(height: 2),
        const Text('QR + карта + наличные',
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ])),
      const SizedBox(height: 10),
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(text: 'Скорректировать вручную (необязательно)'),
        const SizedBox(height: 10),
        _AmountField(label: 'Итоговая выручка', controller: _manualCtrl,
            isDark: isDark, hint: _formatMoney(_autoTotal), currency: currency,
            onChanged: (_) => setState(() {})),
      ])),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildStep3(bool isDark, String currency) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      _StepHeader(step: 3, total: _totalSteps, title: 'Касса и инкассация'),
      const SizedBox(height: 16),
      _GlassCard(isDark: isDark, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardLabel(text: 'Наличные в кассе'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _CashField(label: 'Утром',
              controller: _morningCashCtrl, isDark: isDark, currency: currency,
              onChanged: (_) => setState(() {}))),
          const SizedBox(width: 10),
          Expanded(child: _CashField(label: 'Вечером',
              controller: _eveningCashCtrl, isDark: isDark, currency: currency,
              onChanged: (_) => setState(() {}))),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.05 : 0.6),
              borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Касса на завтра утро',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
            Text('${_formatMoney(_tomorrowCash)} $currency', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          ])),
      ])),
      const SizedBox(height: 10),
      _GlassCard(isDark: isDark, child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Была инкассация?', style: TextStyle(fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
          Switch(value: _hasInkass, activeColor: AppColors.orange,
              onChanged: (v) => setState(() {
                _hasInkass = v; if (!v) _inkassCtrl.text = '0'; })),
        ]),
        if (_hasInkass) ...[
          const SizedBox(height: 12),
          _AmountField(label: 'Сумма инкассации', controller: _inkassCtrl,
              isDark: isDark, currency: currency, onChanged: (_) => setState(() {})),
          const SizedBox(height: 6),
          const Text('Остаток в кассе пересчитается автоматически',
              style: TextStyle(fontSize: 11, color: AppColors.orange)),
        ],
      ])),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildStep4(bool isDark, String currency) {
    final writeOffs = _desserts.where((d) => d.writeOff > 0).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      _StepHeader(step: 4, total: _totalSteps, title: 'Итог смены'),
      const SizedBox(height: 16),
      _GlassCard(isDark: isDark, accentColor: AppColors.green,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ИТОГОВАЯ ВЫРУЧКА', style: TextStyle(fontSize: 10,
            color: AppColors.green, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Text('${_formatMoney(_finalTotal)} $currency', style: const TextStyle(
            fontSize: 36, fontWeight: FontWeight.w700,
            color: AppColors.green, letterSpacing: -1)),
        Text(_formattedDate(),
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ])),
      const SizedBox(height: 10),
      _GlassCard(isDark: isDark, child: Column(children: [
        _SummaryRow(label: 'Сотрудники',
            value: _selectedStaff.isEmpty ? '—' : _selectedStaff.join(', '), isDark: isDark),
        _SummaryRow(label: 'QR-код',
            value: '${_formatMoney(double.tryParse(_qrCtrl.text) ?? 0)} $currency', isDark: isDark),
        _SummaryRow(label: 'Банк. карта',
            value: '${_formatMoney(double.tryParse(_cardCtrl.text) ?? 0)} $currency', isDark: isDark),
        _SummaryRow(label: 'Наличные',
            value: '${_formatMoney(double.tryParse(_cashCtrl.text) ?? 0)} $currency', isDark: isDark),
        const _Divider(),
        _SummaryRow(label: 'Касса утром',
            value: '${_formatMoney(double.tryParse(_morningCashCtrl.text) ?? 0)} $currency', isDark: isDark),
        _SummaryRow(label: 'Касса вечером',
            value: '${_formatMoney(double.tryParse(_eveningCashCtrl.text) ?? 0)} $currency', isDark: isDark),
        if (_hasInkass) _SummaryRow(label: 'Инкассация',
            value: '${_formatMoney(double.tryParse(_inkassCtrl.text) ?? 0)} $currency', isDark: isDark),
        _SummaryRow(label: 'Касса на завтра',
            value: '${_formatMoney(_tomorrowCash)} $currency', isDark: isDark, highlight: true),
        if (writeOffs.isNotEmpty) ...[
          const _Divider(),
          ...writeOffs.map((d) => _SummaryRow(
              label: d.writeOffType == WriteOffType.spoilage ? '🗑 Порча' : '📦 Списание',
              value: '${d.name}: ${d.writeOff} шт',
              isDark: isDark, isWarning: true)),
        ],
        if (_manualWriteOffs.isNotEmpty) ...[
          const _Divider(),
          ..._manualWriteOffs.map((m) => _SummaryRow(
              label: m.type == WriteOffType.spoilage ? '🗑 Порча' : '📦 Списание',
              value: '${m.name}: ${m.quantity} ${m.unit}',
              isDark: isDark, isWarning: true)),
        ],
      ])),
      const SizedBox(height: 16),
      _CardLabel(text: 'Отправить отчёт'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _ShareButton(icon: Icons.chat_rounded, label: 'WhatsApp',
            color: const Color(0xFF25D366), isDark: isDark, onTap: _onSubmit)),
        const SizedBox(width: 10),
        Expanded(child: _ShareButton(icon: Icons.send_rounded, label: 'Telegram',
            color: const Color(0xFF2AABEE), isDark: isDark, onTap: _onSubmit)),
      ]),
      const SizedBox(height: 10),
      _ShareButton(icon: Icons.picture_as_pdf_rounded, label: 'Скачать PDF',
          color: AppColors.orange, isDark: isDark, onTap: _onSubmit, fullWidth: true),
      const SizedBox(height: 16),
    ]);
  }

  Widget _buildBottomBar(bool isDark) {
    final isLast = _step == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(isDark ? 0.06 : 0.0)))),
      child: Row(children: [
        if (_step > 0) ...[
          Expanded(child: OutlinedButton(onPressed: _back,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: AppColors.muted),
              child: const Text('Назад'))),
          const SizedBox(width: 12),
        ],
        Expanded(flex: 2, child: ElevatedButton(onPressed: _next,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isLast ? AppColors.green : AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0),
            child: Text(isLast ? '✓ Закрыть смену' : 'Далее →',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
      ]),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['','января','февраля','марта','апреля','мая','июня',
        'июля','августа','сентября','октября','ноября','декабря'];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  String _formatMoney(double v) {
    if (v == 0) return '0';
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }
}

// ── Виджеты ───────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isRed;
  const _TypeChip({required this.label, required this.selected,
      required this.onTap, required this.isDark, this.isRed = false});
  @override
  Widget build(BuildContext context) {
    final color = isRed ? Colors.redAccent : AppColors.orange;
    return GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: selected ? color : AppColors.muted.withOpacity(0.3))),
        child: Text(label, style: TextStyle(fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : AppColors.muted))));
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child; final bool isDark; final Color? accentColor;
  const _GlassCard({required this.child, required this.isDark, this.accentColor});
  @override
  Widget build(BuildContext context) {
    final a = accentColor;
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            color: a != null ? a.withOpacity(isDark ? 0.08 : 0.05)
                : Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: a != null ? a.withOpacity(0.25)
                : Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
          child: child)));
  }
}

class _CardLabel extends StatelessWidget {
  final String text; const _CardLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: AppColors.muted, letterSpacing: 0.6));
}

class _StepHeader extends StatelessWidget {
  final int step, total; final String title;
  const _StepHeader({required this.step, required this.total, required this.title});
  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Шаг $step из $total', style: const TextStyle(
        fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w500)),
    const SizedBox(height: 4),
    Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white : const Color(0xFF1A1A2E))),
  ]);
}

class _DessertRow extends StatelessWidget {
  final String name; final int value;
  final ValueChanged<int> onChanged; final bool isDark; final bool isWriteOff;
  const _DessertRow({required this.name, required this.value,
      required this.onChanged, required this.isDark, this.isWriteOff = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Text(name, style: TextStyle(fontSize: 13,
          color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1A1A2E)))),
      _QtyBtn(icon: Icons.remove, isDark: isDark,
          onTap: () { if (value > 0) onChanged(value - 1); }),
      SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
      _QtyBtn(icon: Icons.add, isDark: isDark, onTap: () => onChanged(value + 1)),
    ]));
}

class _QtyBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool isDark;
  const _QtyBtn({required this.icon, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 30, height: 30,
      decoration: BoxDecoration(color: Colors.white.withOpacity(isDark ? 0.08 : 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.3))),
      child: Icon(icon, size: 16,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E))));
}

class _PaymentRow extends StatelessWidget {
  final IconData icon; final String label, hint;
  final TextEditingController controller; final Color color;
  final bool isDark; final ValueChanged<String> onChanged;
  final String currency;
  const _PaymentRow({required this.icon, required this.label, required this.hint,
      required this.controller, required this.color, required this.isDark, required this.onChanged, required this.currency});
      
        
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(14),
    child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          SizedBox(width: 110, child: TextField(controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged, textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
              decoration: InputDecoration(suffixText: currency,
                  suffixStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, filled: false,
                  contentPadding: EdgeInsets.zero))),
        ]))));
}

class _AmountField extends StatelessWidget {
  final String label; final TextEditingController controller;
  final bool isDark; final String? hint; final ValueChanged<String>? onChanged;
  final String currency;
  const _AmountField({required this.label, required this.controller,
      required this.isDark, this.hint, this.onChanged, this.currency = '₸'});
      
        
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontSize: 13,
        color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1A1A2E)))),
    SizedBox(width: 120, child: TextField(controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged, textAlign: TextAlign.right,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        decoration: InputDecoration(hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
            suffixText: currency, suffixStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
            border: InputBorder.none, enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero))),
  ]);
}

class _CashField extends StatelessWidget {
  final String label; final TextEditingController controller;
  final bool isDark; final ValueChanged<String>? onChanged;
  final String currency;
  const _CashField({required this.label, required this.controller,
      required this.isDark, this.onChanged, this.currency = '₸'});
      
        
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      const SizedBox(height: 4),
      TextField(controller: controller, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          decoration: InputDecoration(border: InputBorder.none,
              enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              filled: false, contentPadding: EdgeInsets.zero,
              suffixText: currency, suffixStyle: const TextStyle(color: AppColors.muted, fontSize: 13))),
    ]));
}

class _SummaryRow extends StatelessWidget {
  final String label, value; final bool isDark, highlight, isWarning;
  const _SummaryRow({required this.label, required this.value, required this.isDark,
      this.highlight = false, this.isWarning = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      Flexible(child: Text(value, textAlign: TextAlign.right,
          style: TextStyle(fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              color: isWarning ? Colors.redAccent
                  : highlight ? AppColors.orange
                  : isDark ? Colors.white : const Color(0xFF1A1A2E)))),
    ]));
}

class _ShareButton extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final bool isDark; final VoidCallback onTap; final bool fullWidth;
  const _ShareButton({required this.icon, required this.label, required this.color,
      required this.isDark, required this.onTap, this.fullWidth = false});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ])));
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withOpacity(0.1));
}

class _ConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Закрыть смену?',
          style: TextStyle(fontWeight: FontWeight.w600)),
      content: const Text(
          'Будет сформирован PDF-отчёт. Вы сможете отправить его через WhatsApp или Telegram.',
          style: TextStyle(color: AppColors.muted, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.muted))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Закрыть и PDF')),
      ]);
  }
}

