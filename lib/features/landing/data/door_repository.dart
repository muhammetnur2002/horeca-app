/// Две двери одной платформы: сотрудник и заведение. Выбор делается на
/// лендинге и хранится на устройстве. Маршрут `/` заведения лендинг не
/// заменяет: он стоит перед входом, пока дверь не выбрана.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horeca_app/app/di.dart';

enum AppDoor { staff, venue }

const doorPrefsKey = 'akyl_door_v1';

AppDoor? decodeDoor(String? raw) => AppDoor.values.asNameMap()[raw];

/// Дверь при запуске. Кто уже работал с заведением на этом телефоне —
/// входил в облако или включал PIN — сразу попадает в заведение, лендинг
/// живых пользователей не останавливает.
AppDoor? initialDoor(SharedPreferences prefs) {
  final saved = decodeDoor(prefs.getString(doorPrefsKey));
  if (saved != null) return saved;
  if (prefs.getBool('account_ever_logged_in') ?? false) return AppDoor.venue;
  for (final key in prefs.getKeys()) {
    if (key.startsWith('pins_enabled') && (prefs.getBool(key) ?? false)) {
      return AppDoor.venue;
    }
  }
  return null;
}

class DoorNotifier extends StateNotifier<AppDoor?> {
  final SharedPreferences _prefs;

  DoorNotifier(this._prefs) : super(initialDoor(_prefs));

  void choose(AppDoor door) {
    _prefs.setString(doorPrefsKey, door.name);
    state = door;
  }

  /// «Сменить вход»: снова показать лендинг. Данные обеих дверей остаются.
  void reset() {
    _prefs.remove(doorPrefsKey);
    state = null;
  }
}

final doorProvider = StateNotifierProvider<DoorNotifier, AppDoor?>((ref) {
  return DoorNotifier(ref.read(sharedPreferencesProvider));
});
