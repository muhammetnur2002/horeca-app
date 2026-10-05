import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/app/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('палитра по умолчанию — Орбита, неизвестный ключ тоже даёт Орбиту', () {
    expect(AkylPalette.fromKey(null), AkylPalette.orbit);
    expect(AkylPalette.fromKey('нет такой'), AkylPalette.orbit);
  });

  test('выбор палитры сохраняется и меняет цвета AppColors', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);

    expect(c.read(paletteProvider), AkylPalette.orbit);
    await c.read(paletteProvider.notifier).setPalette(AkylPalette.mars);
    expect(prefs.getString('app_palette'), 'mars');
    expect(AppColors.orange, AkylColors.of(AkylPalette.mars).primary);

    // Новый запуск читает сохранённую палитру.
    final c2 = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c2.dispose);
    expect(c2.read(paletteProvider), AkylPalette.mars);
    AppColors.applyPalette(AkylPalette.orbit);
  });

  test('у каждой палитры свои акценты', () {
    final primaries =
        AkylPalette.values.map((p) => AkylColors.of(p).primary).toSet();
    expect(primaries.length, AkylPalette.values.length);
  });
}
