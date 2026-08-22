import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

/// Хранит флаг "тур по приложению уже показан". Тур должен появляться
/// ровно один раз — сразу после первого входа/регистрации — а дальше
/// не всплывать сам, только по кнопке "Показать обучение заново"
/// в разделе "О программе".
class OnboardingRepository extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _seenKey = 'onboarding_seen';

  OnboardingRepository(this._prefs)
      : super(_prefs.getBool(_seenKey) ?? false);

  bool get seen => state;

  Future<void> markSeen() async {
    await _prefs.setBool(_seenKey, true);
    state = true;
  }

  /// Позволяет пользователю пересмотреть тур вручную из "О программе".
  Future<void> resetForReplay() async {
    await _prefs.setBool(_seenKey, false);
    state = false;
  }
}

final onboardingRepositoryProvider =
    StateNotifierProvider<OnboardingRepository, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingRepository(prefs);
});
