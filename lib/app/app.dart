import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:horeca_app/app/app_theme.dart';
import 'package:horeca_app/app/routes.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/splash/splash_screen.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_screen.dart';
import 'package:horeca_app/features/account/data/account_repository.dart';
import 'package:horeca_app/features/account/data/cloud_auto_sync.dart';
import 'package:horeca_app/features/account/data/cloud_sync_service.dart';
import 'package:horeca_app/features/account/presentation/account_gate_screen.dart';
import 'package:horeca_app/features/venue/data/venue_repository.dart';

export 'app_theme.dart';

/// Корневой виджет приложения: заставка, гейт входа/PIN и MaterialApp.router
/// с темами. Цвета и ThemeData вынесены в app_theme.dart (и реэкспортированы
/// отсюда, чтобы `import '.../app/app.dart'` по-прежнему давал AppColors).
class HorecaApp extends ConsumerStatefulWidget {
  const HorecaApp({super.key});

  @override
  ConsumerState<HorecaApp> createState() => _HorecaAppState();
}

class _HorecaAppState extends ConsumerState<HorecaApp> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _accountGateSkipped = false;
  static const _accountGateSkippedKey = 'account_gate_skipped';
  Timer? _syncTimer;
  static const _syncInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Прозрачный статус-бар
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _accountGateSkipped =
        ref.read(sharedPreferencesProvider).getBool(_accountGateSkippedKey) ?? false;
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _showSplash = false);
    });
    // Периодическая фоновая синхронизация, пока приложение открыто — не
    // только по выходу из экрана, чтобы данные не терялись при долгих
    // сессиях или если приложение убьют из "недавних" без штатного paused.
    _syncTimer = Timer.periodic(_syncInterval, (_) => _syncIfLoggedIn());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncIfLoggedIn() {
    final account = ref.read(accountRepositoryProvider);
    if (account.isLoggedIn && account.uid != null) {
      // Синхронизируем только активное на этом устройстве заведение — это
      // устройство обычно работает с одним конкретным заведением (касса
      // на месте), а не со всеми пятью сразу.
      final venueCode = ref.read(venueRepositoryProvider).activeVenueCode;
      CloudSyncService.syncSmart(
          account.uid!, ref.read(sharedPreferencesProvider), venueCode);
    }
  }

  // Синхронизируем при сворачивании (отправляем свои изменения) и при
  // возврате в приложение (подтягиваем то, что могло измениться на другом
  // устройстве, пока это было в фоне) — используем "умную" синхронизацию
  // с учётом времени последнего изменения, а не слепую перезапись.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Досылаем изменение, которое ещё ждёт дебаунса (см. cloud_auto_sync.dart),
      // чтобы не потерять его при сворачивании прямо в это окно.
      ref.read(cloudAutoSyncProvider).flush();
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) {
      _syncIfLoggedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    if (_showSplash) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: SplashScreen(),
      );
    }

    final accountState = ref.watch(accountRepositoryProvider);
    // Если это устройство хоть раз успешно логинилось в облачный аккаунт —
    // больше никогда не показываем экран входа автоматически, даже если
    // именно сейчас Firebase недоступен (нет сети, VPN, временный сбой при
    // холодном старте). Сессия сама восстановится в фоне, когда сеть
    // появится; до этого работаем как обычно локально.
    final everLoggedIn = ref.read(accountRepositoryProvider.notifier).everLoggedIn;

    if (!accountState.isLoggedIn && !_accountGateSkipped && !everLoggedIn) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
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
        home: AccountGateScreen(
          onSkip: () {
            ref.read(sharedPreferencesProvider).setBool(_accountGateSkippedKey, true);
            setState(() => _accountGateSkipped = true);
          },
        ),
      );
    }

    final authState = ref.watch(authRepositoryProvider);
    final pinsEnabled = ref.read(authRepositoryProvider.notifier).pinsEnabled;

    if (pinsEnabled && !authState.isLoggedIn) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
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
        home: const PinScreen(),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],

      theme: buildAppLightTheme(),
      darkTheme: buildAppDarkTheme(),

      routerConfig: router,
    );
  }
}
