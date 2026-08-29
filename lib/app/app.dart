import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:horeca_app/app/routes.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/app/theme.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/splash/splash_screen.dart';
import 'package:horeca_app/features/auth/data/auth_repository.dart';
import 'package:horeca_app/features/auth/presentation/pin_screen.dart';

// AppColors и AppTheme живут в theme.dart; реэкспорт нужен, чтобы уже
// написанные `import '.../app/app.dart'` продолжали видеть AppColors.
export 'package:horeca_app/app/theme.dart';

class HorecaApp extends ConsumerStatefulWidget {
  const HorecaApp({super.key});

  @override
  ConsumerState<HorecaApp> createState() => _HorecaAppState();
}

class _HorecaAppState extends ConsumerState<HorecaApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Прозрачный статус-бар
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _dismissSplash() {
    if (!_showSplash || !mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Заставка сама сообщает, когда анимация закончилась (раньше здесь висел
    // жёсткий Future.delayed на 10 секунд при каждом холодном старте).
    if (_showSplash) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SplashScreen(onFinished: _dismissSplash),
      );
    }

    final auth = ref.watch(authRepositoryProvider);

    if (auth.needsAuthentication) {
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
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
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
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
