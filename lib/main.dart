import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:horeca_app/app/app.dart';
import 'package:horeca_app/app/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Приложение обязано работать полностью офлайн — поэтому инициализация
    // Firebase не должна валить старт, если что-то пошло не так (например,
    // некорректный google-services.json). AccountGateScreen и так умеет
    // работать без аккаунта, если Firebase недоступен.
    bool firebaseReady = false;
    try {
      // Таймаут — страховка от сетей, где firebase_core_web не получает ни
      // успеха, ни ошибки: он подгружает Firebase JS SDK через динамический
      // import() из gstatic.com прямо в браузере, и если этот import
      // зависает (медленная/фильтрующая сеть, а не явный отказ), то Future
      // от Firebase.initializeApp() может никогда не завершиться — тогда
      // runApp() ниже не вызовется вообще, и вместо офлайн-режима
      // пользователь увидит бесконечный пустой экран.
      await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase init failed, продолжаем офлайн: $e');
    }

    if (firebaseReady) {
      // App Check — защищает Auth/Firestore от вызовов не из настоящего
      // приложения (боты, скрипты, реверс-инжиниринг API-ключа).
      // Play Integrity должен быть подключён в Firebase Console →
      // App Check → Apps → Android, иначе токены не будут проходить проверку.
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          // App Attest — аппаратная аттестация устройства (iOS 14+), с
          // откатом на DeviceCheck на старых устройствах/симуляторе.
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.appAttestWithDeviceCheckFallback,
        );
      } catch (e) {
        debugPrint('App Check activation failed: $e');
      }

      // Crashlytics — сбор крашей и необработанных ошибок.
      try {
        FlutterError.onError = (details) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e) {
        debugPrint('Crashlytics setup failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const HorecaApp(),
      ),
    );
  }, (error, stack) {
    // Ошибки вне Flutter-фреймворка (например, в async-коде) — тоже в Crashlytics,
    // если Firebase успел инициализироваться; иначе просто в консоль.
    debugPrint('Незахваченная ошибка: $error');
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  });
}
