import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/iiko/data/iiko_repository.dart';
import 'package:horeca_app/features/iiko/data/iiko_request_suggester.dart';
import 'package:horeca_app/features/iiko/data/iiko_service.dart';
import 'package:horeca_app/features/iiko/presentation/iiko_widgets.dart';
import 'package:horeca_app/features/request/domain/usecases/request_state.dart';
import 'package:horeca_app/features/settings/data/settings_repository.dart';

/// Экран подключения и остатков iiko. Мелкие карточки/строки вынесены в
/// iiko_widgets.dart, чтобы не раздувать build().
class IikoScreen extends ConsumerStatefulWidget {
  const IikoScreen({super.key});
  @override
  ConsumerState<IikoScreen> createState() => _IikoScreenState();
}

class _IikoScreenState extends ConsumerState<IikoScreen> {
  final _loginCtrl = TextEditingController();
  final _service = IikoService();
  bool _loading = false;
  String? _error;

  List<IikoOrganization> _orgs = [];
  List<IikoStore> _stores = [];
  List<IikoBalanceItem> _balances = [];
  String? _token;
  String? _selectedOrgId;
  String? _selectedOrgName;
  final Set<String> _selectedStoreIds = {};

  @override
  void dispose() {
    _loginCtrl.dispose();
    super.dispose();
  }

  void _loadDemo() {
    setState(() {
      _balances = getDemoBalances();
      _loading = false;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Демо-режим: показаны тестовые остатки', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.muted,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _connect() async {
    if (_loginCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _service.getAccessToken(_loginCtrl.text.trim());
      final orgs = await _service.getOrganizations(token);
      if (!mounted) return;
      setState(() {
        _token = token;
        _orgs = orgs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось подключиться. Проверьте API-логин и интернет.';
        _loading = false;
      });
    }
  }

  Future<void> _selectOrg(IikoOrganization org) async {
    setState(() { _loading = true; _error = null; });
    try {
      final stores = await _service.getStores(_token!, org.id);
      if (!mounted) return;
      setState(() {
        _selectedOrgId = org.id;
        _selectedOrgName = org.name;
        _stores = stores;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось получить список складов.';
        _loading = false;
      });
    }
  }

  Future<void> _saveAndLoadBalance() async {
    if (_selectedStoreIds.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final balances = await _service.getStoreBalance(
        _token!, _selectedOrgId!, _selectedStoreIds.toList(),
      );
      // Сохраняем подключение только после успешного ответа API —
      // иначе при сбое сети останется "подключено", но без данных.
      await ref.read(iikoRepositoryProvider.notifier).saveConnection(
        apiLogin: _loginCtrl.text.trim(),
        organizationId: _selectedOrgId!,
        organizationName: _selectedOrgName!,
      );
      ref.read(iikoRepositoryProvider.notifier).setStoreIds(_selectedStoreIds.toList());
      if (!mounted) return;
      setState(() {
        _balances = balances;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить остатки.';
        _loading = false;
      });
    }
  }

  Future<void> _refreshBalance() async {
    final config = ref.read(iikoRepositoryProvider);
    if (!config.isConnected) return;
    setState(() { _loading = true; _error = null; });
    try {
      final apiLogin = await ref.read(iikoRepositoryProvider.notifier).getApiLogin();
      if (apiLogin == null) throw Exception('Учётные данные iiko не найдены');
      final token = await _service.getAccessToken(apiLogin);
      final balances = await _service.getStoreBalance(
        token, config.organizationId!, config.storeIds,
      );
      if (!mounted) return;
      setState(() {
        _token = token;
        _balances = balances;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось обновить остатки.';
        _loading = false;
      });
    }
  }

  /// Сопоставляет текущие остатки iiko с товарами каталога (по названию) и
  /// предлагает готовую заявку на всё, что ниже minStock — раньше это было
  /// в списке незавершённых задач проекта. Работает и в демо-режиме.
  Future<void> _createRequestFromBalances() async {
    final products = ref.read(settingsRepositoryProvider).products;
    final suggestions =
        buildLowStockSuggestions(balances: _balances, products: products);

    if (suggestions.isEmpty) {
      final anyMinStockConfigured = products.any((p) => p.minStock != null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(anyMinStockConfigured
            ? 'Все остатки в норме — дозаказ не требуется.'
            : 'Сначала задайте минимальный остаток для товаров: Настройки → Товары.'),
        backgroundColor: anyMinStockConfigured ? AppColors.green : AppColors.muted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showLowStockRequestDialog(
      context,
      isDark: isDark,
      suggestions: suggestions,
    );
    if (!confirmed || !mounted) return;

    final items = suggestions
        .map((s) => RequestItem(
              productId: s.product.id,
              productName: s.product.name,
              quantity: s.suggestedQuantity,
              unit: s.product.unit,
            ))
        .toList();
    ref.read(requestStateProvider.notifier).prefillFromSuggestions(items);
    if (mounted) context.push('/request');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = ref.watch(iikoRepositoryProvider);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('iiko', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (config.isConnected)
            IconButton(
              icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
              onPressed: () {
                ref.read(iikoRepositoryProvider.notifier).disconnect();
                setState(() {
                  _orgs = []; _stores = []; _balances = [];
                  _token = null; _selectedOrgId = null;
                  _selectedStoreIds.clear();
                  _loginCtrl.clear();
                });
              },
            ),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (config.isConnected && _balances.isEmpty) ...[
                ConnectedCard(
                  orgName: config.organizationName ?? '',
                  isDark: isDark,
                  onRefresh: _refreshBalance,
                  loading: _loading,
                ),
              ] else if (!config.isConnected && _orgs.isEmpty) ...[
                LoginCard(
                  controller: _loginCtrl,
                  isDark: isDark,
                  loading: _loading,
                  onConnect: _connect,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _loadDemo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.muted.withOpacity(0.08),
                      border: Border.all(color: AppColors.muted.withOpacity(0.25))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.science_outlined, color: AppColors.muted, size: 18),
                      const SizedBox(width: 8),
                      const Text('Демо-режим (без iiko)',
                          style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ] else if (_orgs.isNotEmpty && _selectedOrgId == null) ...[
                Text('Выберите организацию', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 12),
                ..._orgs.map((o) => SelectRow(
                  title: o.name, isDark: isDark,
                  onTap: () => _selectOrg(o),
                )),
              ] else if (_stores.isNotEmpty && _balances.isEmpty) ...[
                Text('Выберите склады', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 12),
                ..._stores.map((s) => CheckRow(
                  title: s.name, isDark: isDark,
                  checked: _selectedStoreIds.contains(s.id),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedStoreIds.add(s.id);
                    } else {
                      _selectedStoreIds.remove(s.id);
                    }
                  }),
                )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _saveAndLoadBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Загрузить остатки'),
                ),
              ],

              if (_error != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),

              if (_balances.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Остатки на складе', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: AppColors.orange),
                    onPressed: _loading ? null : _refreshBalance,
                  ),
                ]),
                const SizedBox(height: 8),
                ..._balances.map((b) => BalanceRow(item: b, isDark: isDark)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _createRequestFromBalances,
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Создать заявку по остаткам'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
