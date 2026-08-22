/// Экран "Закрытие смены" — 4 шага (смена/десерты → оплата → касса → итог).
/// Сам экран только хранит состояние и переключает шаги; вёрстка каждого
/// шага вынесена в shift_close_step1..4.dart, общие виджеты — в
/// shift_close_widgets.dart, индикатор шагов и нижняя панель — в
/// shift_close_stepper.dart, чтобы этот файл не разрастался.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/analytics/data/analytics_repository.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';
import 'package:horeca_app/features/shift_close/data/shift_draft_provider.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_format.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_models.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_pdf.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_screen_steps.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_stepper.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_validation.dart';
import 'package:horeca_app/features/shift_close/presentation/shift_close_widgets.dart';

class ShiftCloseScreen extends ConsumerStatefulWidget {
  const ShiftCloseScreen({super.key});

  @override
  ConsumerState<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends ConsumerState<ShiftCloseScreen> {
  final ScrollController _scrollController = ScrollController();
  int _step = 0;
  final int _totalSteps = 4;
  final Set<String> _selectedStaff = {};
  List<DessertItem> _desserts = [];
  bool _dessertsLoaded = false;
  final List<ManualWriteOff> _manualWriteOffs = [];
  final _dessertSearchCtrl = TextEditingController();
  String _dessertSearch = '';

  final _qrCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _manualCtrl = TextEditingController();
  final _morningCashCtrl = TextEditingController();
  final _eveningCashCtrl = TextEditingController();
  final _inkassCtrl = TextEditingController();
  bool _hasInkass = false;

  double get _autoTotal =>
      (double.tryParse(_qrCtrl.text) ?? 0) +
      (double.tryParse(_cardCtrl.text) ?? 0) +
      (double.tryParse(_cashCtrl.text) ?? 0);

  double get _finalTotal => double.tryParse(_manualCtrl.text) ?? _autoTotal;

  double get _tomorrowCash {
    final evening = double.tryParse(_eveningCashCtrl.text) ?? 0;
    final inkass = _hasInkass ? (double.tryParse(_inkassCtrl.text) ?? 0) : 0;
    return evening - inkass;
  }

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  void _loadDraft() {
    final draft = ref.read(shiftDraftProvider);
    _step = draft.step;
    _selectedStaff.addAll(draft.selectedStaff);
    if (draft.dessertsLoaded) {
      _desserts = draft.desserts;
      _dessertsLoaded = true;
    }
    _manualWriteOffs.addAll(draft.manualWriteOffs);
    _qrCtrl.text = draft.qr;
    _cardCtrl.text = draft.card;
    _cashCtrl.text = draft.cash;
    _manualCtrl.text = draft.manual;
    _morningCashCtrl.text = draft.morningCash;
    _eveningCashCtrl.text = draft.eveningCash;
    _inkassCtrl.text = draft.inkass;
    _hasInkass = draft.hasInkass;
  }

  ShiftDraft _buildDraft() {
    return ShiftDraft(
      step: _step,
      selectedStaff: Set.from(_selectedStaff),
      desserts: _desserts,
      dessertsLoaded: _dessertsLoaded,
      manualWriteOffs: List.from(_manualWriteOffs),
      qr: _qrCtrl.text,
      card: _cardCtrl.text,
      cash: _cashCtrl.text,
      manual: _manualCtrl.text,
      morningCash: _morningCashCtrl.text,
      eveningCash: _eveningCashCtrl.text,
      inkass: _inkassCtrl.text,
      hasInkass: _hasInkass,
    );
  }

  @override
  void deactivate() {
    // Сохраняем черновик при уходе с экрана (сворачивание, переключение
    // вкладок), чтобы введённые суммы не терялись, если пользователь
    // не дошёл до конца — используем microtask, т.к. во время deactivate
    // менять состояние провайдеров напрямую нельзя.
    final draft = _buildDraft();
    Future.microtask(() => ref.read(shiftDraftProvider.notifier).save(draft));
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _qrCtrl.dispose();
    _cardCtrl.dispose();
    _cashCtrl.dispose();
    _manualCtrl.dispose();
    _morningCashCtrl.dispose();
    _eveningCashCtrl.dispose();
    _inkassCtrl.dispose();
    _dessertSearchCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final warning = validateShiftStep(
      step: _step,
      selectedStaff: _selectedStaff,
      desserts: _desserts,
      qrController: _qrCtrl,
      cardController: _cardCtrl,
      cashController: _cashCtrl,
      morningCashController: _morningCashCtrl,
      eveningCashController: _eveningCashCtrl,
    );
    if (warning != null) {
      _showWarning(warning);
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _onSubmit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _onSubmit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmCloseShiftDialog(),
    );
    if (confirm != true || !mounted) return;

    // Сохраняем запись для аналитики.
    final writeOffsMap = <String, int>{};
    for (final d in _desserts.where((d) => d.writeOff > 0)) {
      writeOffsMap[d.name] = d.writeOff;
    }
    for (final m in _manualWriteOffs) {
      writeOffsMap[m.name] = (writeOffsMap[m.name] ?? 0) + m.quantity;
    }
    ref.read(analyticsRepositoryProvider).addShift(ShiftRecord(
          date: DateTime.now(),
          revenue: _finalTotal,
          qr: double.tryParse(_qrCtrl.text) ?? 0,
          card: double.tryParse(_cardCtrl.text) ?? 0,
          cash: double.tryParse(_cashCtrl.text) ?? 0,
          morningCash: double.tryParse(_morningCashCtrl.text) ?? 0,
          eveningCash: double.tryParse(_eveningCashCtrl.text) ?? 0,
          writeOffs: writeOffsMap,
        ));

    await ShiftClosePdf.generateAndShare(
      currency: ref.read(settingsRepositoryProvider).currency,
      context: context,
      staffName: _selectedStaff.isEmpty ? '—' : _selectedStaff.join(', '),
      desserts: _desserts,
      manualWriteOffs: _manualWriteOffs,
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
    ref.read(shiftDraftProvider.notifier).reset();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(settingsRepositoryProvider).currency;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Закрытие смены',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                shiftCloseFormattedDate(),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ),
        ],
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
                      ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            const SizedBox(height: 8),
            ShiftStepperIndicator(
              currentStep: _step,
              totalSteps: _totalSteps,
              isDark: isDark,
              onStepTap: (di) => setState(() => _step = di),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentStep(isDark, currency),
              ),
            ),
            ShiftBottomBar(
              step: _step,
              totalSteps: _totalSteps,
              isDark: isDark,
              onBack: _back,
              onNext: _next,
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCurrentStep(bool isDark, String currency) {
    return buildShiftCurrentStep(
      step: _step,
      context: context,
      ref: ref,
      setState: setState,
      isMounted: () => mounted,
      isDark: isDark,
      totalSteps: _totalSteps,
      currency: currency,
      selectedStaff: _selectedStaff,
      desserts: _desserts,
      dessertsLoaded: _dessertsLoaded,
      manualWriteOffs: _manualWriteOffs,
      dessertSearchController: _dessertSearchCtrl,
      dessertSearch: _dessertSearch,
      onDessertSearchChanged: (v) => _dessertSearch = v,
      onDessertsLoaded: (loaded) {
        _desserts = loaded;
        _dessertsLoaded = true;
      },
      qrController: _qrCtrl,
      cardController: _cardCtrl,
      cashController: _cashCtrl,
      manualController: _manualCtrl,
      morningCashController: _morningCashCtrl,
      eveningCashController: _eveningCashCtrl,
      inkassController: _inkassCtrl,
      hasInkass: _hasInkass,
      onHasInkassChanged: (v) => _hasInkass = v,
      autoTotal: _autoTotal,
      finalTotal: _finalTotal,
      tomorrowCash: _tomorrowCash,
      onSubmit: _onSubmit,
    );
  }
}
