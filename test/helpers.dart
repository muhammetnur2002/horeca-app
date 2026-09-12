import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Несколько экранов крутят бесконечные анимации (логотип в AppBar,
/// иконка в настройках), поэтому `pumpAndSettle` там зависает.
/// Во всех тестах используем ограниченную по времени прокрутку кадров.
Future<void> settle(WidgetTester tester,
    [Duration step = const Duration(milliseconds: 120)]) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(step);
  }
}

/// Тесты гоняем на размере обычного телефона, а не на дефолтных 800x600.
Future<void> usePhoneSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<SharedPreferences> freshPrefs([Map<String, Object> seed = const {}]) {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(seed));
  return SharedPreferences.getInstance();
}

/// Оборачивает экран в минимальное окружение приложения: провайдеры,
/// локализация и темы такие же, как в бою.
Widget wrapScreen(Widget child, SharedPreferences prefs,
    {List<Override> overrides = const [], ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
    child: MaterialApp(
      themeMode: themeMode,
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: child,
    ),
  );
}

/// Полное приложение с уже пройденной заставкой.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  SharedPreferences prefs, {
  List<Override> overrides = const [],
}) async {
  await usePhoneSurface(tester);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    ...overrides,
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const HorecaApp(),
  ));
  // Заставка: ждём её полную длительность плюс кадр на переключение.
  await tester.pump(const Duration(milliseconds: 3400));
  await settle(tester);
  return container;
}

/// Тапает по первому виджету с указанным текстом, предварительно
/// подкручивая его в зону видимости (вкладки и длинные списки).
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).first;
  await ensureTappable(tester, finder);
  await tester.tap(finder);
  await settle(tester);
}

Future<void> tapWidget(WidgetTester tester, Finder finder) async {
  await ensureTappable(tester, finder);
  await tester.tap(finder);
  await settle(tester);
}

/// Прокручивает виджет в середину области видимости. Именно в середину:
/// экраны используют extendBodyBehindAppBar, и элемент, поднятый к самому
/// верху, оказывается под прозрачным AppBar и не принимает нажатия.
Future<void> ensureTappable(WidgetTester tester, Finder finder) async {
  final elements = finder.evaluate();
  if (elements.isEmpty) return;
  try {
    await Scrollable.ensureVisible(
      elements.first,
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pump();
  } catch (_) {
    // виджет не в прокручиваемой области — тапаем как есть
  }
}

/// Закрывает открытую модальную шторку.
Future<void> closeSheet(WidgetTester tester) async {
  final ctx = tester.element(find.byType(Navigator).last);
  Navigator.of(ctx).pop();
  await settle(tester);
}

/// FAB конкретной вкладки настроек: посещённые вкладки остаются в дереве,
/// поэтому одновременно живут несколько FAB.
Finder fabOf(Type tab) => find.descendant(
      of: find.byType(tab),
      matching: find.byType(FloatingActionButton),
    );
