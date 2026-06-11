import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:horeca_app/app/routes.dart';
import 'package:horeca_app/app/di.dart';
import 'package:horeca_app/core/localization/l10n/app_localizations.dart';
import 'package:horeca_app/features/splash/splash_screen.dart';

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
    // Через 3 секунды убираем сплеш-скрин
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    final mainApp = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      locale: const Locale('ru'), // всегда русский
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
        cardColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF2E4A3A),
          secondary: Colors.deepOrange.shade300,
          surface: const Color(0xFFF5F5DC),
          onSurface: Colors.black87,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E4A3A)),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
          labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF2E4A3A),
            foregroundColor: Colors.white,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF87CEEB),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1C2B),
        colorScheme: ColorScheme.dark(
          primary: Colors.orange.shade300,
          secondary: Colors.deepPurple.shade300,
          surface: const Color(0xFF1E1E1E),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
          labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withOpacity(0.3),
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      routerConfig: router,
    );

    // Оборачиваем в Directionality, чтобы Stack и всё внутри имели доступ к текстовому направлению
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          mainApp,
          if (_showSplash) const SplashScreen(),
        ],
      ),
    );
  }
}