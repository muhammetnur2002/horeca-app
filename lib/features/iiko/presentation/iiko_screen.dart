import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/iiko/data/iiko_repository.dart';
import 'package:horeca_app/features/iiko/data/iiko_service.dart';


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
      setState(() {
        _token = token;
        _orgs = orgs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось подключиться. Проверьте API-логин.';
        _loading = false;
      });
    }
  }

  Future<void> _selectOrg(IikoOrganization org) async {
    setState(() { _loading = true; _error = null; });
    try {
      final stores = await _service.getStores(_token!, org.id);
      setState(() {
        _selectedOrgId = org.id;
        _selectedOrgName = org.name;
        _stores = stores;
        _loading = false;
      });
    } catch (e) {
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
      ref.read(iikoRepositoryProvider.notifier).saveConnection(
        apiLogin: _loginCtrl.text.trim(),
        organizationId: _selectedOrgId!,
        organizationName: _selectedOrgName!,
      );
      ref.read(iikoRepositoryProvider.notifier).setStoreIds(_selectedStoreIds.toList());

      final balances = await _service.getStoreBalance(
        _token!, _selectedOrgId!, _selectedStoreIds.toList(),
      );
      setState(() {
        _balances = balances;
        _loading = false;
      });
    } catch (e) {
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
      final token = await _service.getAccessToken(config.apiLogin!);
      final balances = await _service.getStoreBalance(
        token, config.organizationId!, config.storeIds,
      );
      setState(() {
        _token = token;
        _balances = balances;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось обновить остатки.';
        _loading = false;
      });
    }
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
                _ConnectedCard(
                  orgName: config.organizationName ?? '',
                  isDark: isDark,
                  onRefresh: _refreshBalance,
                  loading: _loading,
                ),
              ] else if (!config.isConnected && _orgs.isEmpty) ...[
  _LoginCard(
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
                ..._orgs.map((o) => _SelectRow(
                  title: o.name, isDark: isDark,
                  onTap: () => _selectOrg(o),
                )),
              ] else if (_stores.isNotEmpty && _balances.isEmpty) ...[
                Text('Выберите склады', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 12),
                ..._stores.map((s) => _CheckRow(
                  title: s.name, isDark: isDark,
                  checked: _selectedStoreIds.contains(s.id),
                  onChanged: (v) => setState(() {
                    if (v == true) _selectedStoreIds.add(s.id);
                    else _selectedStoreIds.remove(s.id);
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
                ..._balances.map((b) => _BalanceRow(item: b, isDark: isDark)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark, loading;
  final VoidCallback onConnect;
  const _LoginCard({required this.controller, required this.isDark, required this.loading, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(isDark ? 0.06 : 0.55),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.store_rounded, color: AppColors.orange, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text('Подключить iiko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor))),
            ]),
            const SizedBox(height: 8),
            Text('Введите API-логин из личного кабинета iikoWeb (раздел интеграции)',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'API-логин',
                hintStyle: const TextStyle(color: AppColors.muted),
                prefixIcon: const Icon(Icons.key_rounded, color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Подключить'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  final String orgName;
  final bool isDark, loading;
  final VoidCallback onRefresh;
  const _ConnectedCard({required this.orgName, required this.isDark, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.green.withOpacity(isDark ? 0.08 : 0.05),
            border: Border.all(color: AppColors.green.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text('Подключено: $orgName', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green, foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Загрузить остатки'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  const _SelectRow({required this.title, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
        child: Row(children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String title;
  final bool isDark, checked;
  final ValueChanged<bool?> onChanged;
  const _CheckRow({required this.title, required this.isDark, required this.checked, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: CheckboxListTile(
        value: checked,
        onChanged: onChanged,
        title: Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
        activeColor: AppColors.orange,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final IikoBalanceItem item;
  final bool isDark;
  const _BalanceRow({required this.item, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(isDark ? 0.06 : 0.6),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.4))),
      child: Row(children: [
        Expanded(child: Text(item.productName, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A2E)))),
        Text('${item.amount} ${item.unit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.orange)),
      ]),
    );
  }
}



