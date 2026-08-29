import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';

class PinSettingsScreen extends ConsumerStatefulWidget {
  const PinSettingsScreen({super.key});
  @override
  ConsumerState<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends ConsumerState<PinSettingsScreen> {
  final _adminCtrl = TextEditingController();
  final _staffCtrl = TextEditingController();

  @override
  void dispose() {
    _adminCtrl.dispose();
    _staffCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final digits = RegExp(r'^\d{4,6}$');
    if (!digits.hasMatch(_adminCtrl.text) || !digits.hasMatch(_staffCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN-код — от 4 до 6 цифр', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_adminCtrl.text == _staffCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN-коды должны отличаться', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final repo = ref.read(authRepositoryProvider.notifier);
    repo.setPins(adminPin: _adminCtrl.text, staffPin: _staffCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('PIN-коды сохранены', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
    _adminCtrl.clear();
    _staffCtrl.clear();
    Navigator.of(context).pop();
  }

  void _disable() {
    final repo = ref.read(authRepositoryProvider.notifier);
    repo.clearPins();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Защита PIN-кодом отключена', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.muted,
      behavior: SnackBarBehavior.floating,
    ));
    setState(() { _adminCtrl.clear(); _staffCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final pinsEnabled = ref.watch(authRepositoryProvider).pinsEnabled;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Управление доступом',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Установите PIN-коды для администратора и сотрудников. '
                'Администратор видит все разделы, включая аналитику и настройки. '
                'Сотрудники видят только рабочие функции.\n\n'
                'Действующие коды не отображаются — они хранятся в виде хеша. '
                'Чтобы сменить их, введите новые значения и сохраните.',
                style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 24),

              Text('PIN-код администратора', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _adminCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                style: TextStyle(color: textColor, letterSpacing: 4),
                decoration: const InputDecoration(
                  hintText: '1234',
                  counterText: '',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppColors.orange),
                ),
              ),
              const SizedBox(height: 20),

              Text('PIN-код сотрудника', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _staffCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                style: TextStyle(color: textColor, letterSpacing: 4),
                decoration: const InputDecoration(
                  hintText: '5678',
                  counterText: '',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.green),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Сохранить и включить', style: TextStyle(fontWeight: FontWeight.w600)),
              ),

              if (pinsEnabled) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _disable,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Отключить защиту PIN-кодом', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}