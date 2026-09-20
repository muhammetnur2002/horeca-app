import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

/// Настройка PIN-кодов конкретного заведения [venue] — не обязательно
/// активного. Работает напрямую с secure storage через статические методы
/// AuthRepository, а не через authRepositoryProvider — тот привязан к
/// АКТИВНОМУ заведению и его слушает app.dart на самом верхнем уровне, так
/// что смена активного заведения прямо здесь моментально меняла бы сессию
/// входа всего приложения (баг, из-за которого экран "тупил" при настройке
/// второго/третьего заведения).
class PinSettingsScreen extends ConsumerStatefulWidget {
  final Venue venue;
  const PinSettingsScreen({super.key, required this.venue});
  @override
  ConsumerState<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends ConsumerState<PinSettingsScreen> {
  final _adminCtrl = TextEditingController();
  final _staffCtrl = TextEditingController();
  bool _pinsReady = false;
  bool _pinsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPins();
  }

  Future<void> _loadCurrentPins() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final adminPin = await AuthRepository.readAdminPinForVenue(widget.venue.code);
    final staffPin = await AuthRepository.readStaffPinForVenue(widget.venue.code);
    if (!mounted) return;
    setState(() {
      _adminCtrl.text = adminPin ?? '';
      _staffCtrl.text = staffPin ?? '';
      _pinsEnabled = AuthRepository.pinsEnabledForVenue(prefs, widget.venue.code);
      _pinsReady = true;
    });
  }

  @override
  void dispose() {
    _adminCtrl.dispose();
    _staffCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_adminCtrl.text.length != 4 || _staffCtrl.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN-код должен быть ровно 4 цифры',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_adminCtrl.text == _staffCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN-коды должны отличаться',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await AuthRepository.writeAdminPinForVenue(
        widget.venue.code, _adminCtrl.text);
    await AuthRepository.writeStaffPinForVenue(
        widget.venue.code, _staffCtrl.text);
    await AuthRepository.setPinsEnabledForVenue(prefs, widget.venue.code, true);

    // Живой экземпляр AuthRepository (если он уже создан для этого или
    // любого другого заведения) кэширует admin/staff PIN в памяти при
    // создании и не знает, что мы только что переписали PIN на диске в
    // обход него. Без инвалидации следующий вход будет сверяться со
    // старым (пустым) значением из кэша и всегда провалится.
    ref.invalidate(authRepositoryProvider);

    if (!mounted) return;
    setState(() => _pinsEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:
          Text('PIN-коды сохранены', style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _disable() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await AuthRepository.clearPinsForVenue(prefs, widget.venue.code);

    // По той же причине: сбрасываем кэш живого AuthRepository после того,
    // как PIN стёрт на диске в обход него.
    ref.invalidate(authRepositoryProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Защита PIN-кодом отключена',
          style: TextStyle(color: Colors.white)),
      backgroundColor: AppColors.muted,
      behavior: SnackBarBehavior.floating,
    ));
    setState(() {
      _adminCtrl.clear();
      _staffCtrl.clear();
      _pinsEnabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final isMultiVenue = ref.watch(venueRepositoryProvider).isMultiVenue;

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
                'Сотрудники видят только рабочие функции.',
                style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
              ),
              if (isMultiVenue) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Настраивается для заведения «${widget.venue.name}» (код ${widget.venue.code}). '
                    'Полный вход: код + этот пароль, например ${widget.venue.code}1234.',
                    style: const TextStyle(fontSize: 12, color: AppColors.orange),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              Text('PIN-код администратора', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _adminCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
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
                maxLength: 4,
                style: TextStyle(color: textColor, letterSpacing: 4),
                decoration: const InputDecoration(
                  hintText: '5678',
                  counterText: '',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.green),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _pinsReady ? _save : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.orange.withOpacity(0.4),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _pinsReady
                    ? const Text('Сохранить и включить', style: TextStyle(fontWeight: FontWeight.w600))
                    : const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),

              if (_pinsEnabled) ...[
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
