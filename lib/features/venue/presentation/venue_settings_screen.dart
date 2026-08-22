import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_settings_screen.dart';
import 'package:horeca_app/features/venue/presentation/venue_settings_dialogs.dart';
import 'package:horeca_app/features/venue/presentation/venue_settings_widgets.dart';

/// Экран управления заведениями (до 5 на один аккаунт). Каждое заведение —
/// это отдельный набор данных (отделы, товары, история, PIN-коды), доступ
/// к которому открывается вводом "код заведения + пароль" на экране PIN,
/// например 02 1234. Диалоги вынесены в venue_settings_dialogs.dart, строка
/// заведения — в venue_settings_widgets.dart.
class VenueSettingsScreen extends ConsumerWidget {
  const VenueSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final venueState = ref.watch(venueRepositoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Заведения',
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: venueState.venues.length >= VenueRepository.maxVenues
          ? null
          : FloatingActionButton(
              onPressed: () => showAddVenueDialog(context, ref, isDark),
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_business_outlined),
            ),
      body: Stack(children: [
        Positioned.fill(
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF0F1629), Color(0xFF1A1040), Color(0xFF0D1F35)]
                            : const [Color(0xFFEEF2FF), Color(0xFFF5F7FF), Color(0xFFEEF2FF)])))),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
            children: [
              Text(
                'До ${VenueRepository.maxVenues} заведений на один аккаунт. '
                'Вход на конкретное заведение: код заведения (2 цифры) + PIN-код '
                'администратора или сотрудника этого заведения, например 021234.',
                style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              ...venueState.venues.map((v) => VenueRow(
                    venue: v,
                    isActive: v.code == venueState.activeVenueCode,
                    canDelete: venueState.venues.length > 1,
                    isDark: isDark,
                    onRename: () => showRenameVenueDialog(context, ref, v, isDark),
                    onSetupPin: () {
                      // PinSettingsScreen работает с PIN-кодами именно этого
                      // заведения напрямую, не переключая активное заведение
                      // (переключение активного задело бы текущую сессию
                      // входа во всём приложении — см. auth_repository.dart).
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PinSettingsScreen(venue: v)));
                    },
                    onDelete: () => showDeleteVenueDialog(context, ref, v, isDark),
                  )),
              if (venueState.venues.length >= VenueRepository.maxVenues) ...[
                const SizedBox(height: 12),
                Text('Достигнут лимит в ${VenueRepository.maxVenues} заведений.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}
