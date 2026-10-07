# Akyl — SaaS для HoReCa

Мобильное и десктопное приложение для автоматизации заведений общепита: учёт остатков, заявки поставщикам, аналитика и закрытие смен. Работает полностью офлайн, синхронизация с облаком — опционально.

## Основные возможности

- **Инвентарь** — учёт складских остатков, подсказки по низким остаткам
- **Заявки** — формирование и отправка заявок поставщикам (PDF, Excel)
- **Интеграция с iiko** — обмен данными с учётной системой
- **Аналитика** — графики и отчёты (fl_chart), экспорт в PDF/Excel
- **Закрытие смены** — сводка по итогам дня
- **Офлайн-first** — вся работа локально, Firebase-синхронизация между устройствами (до 5 заведений на аккаунт)
- **Безопасность** — Firebase Auth, App Check, Crashlytics, PIN-блокировка

## Стек

| Слой | Технологии |
|------|-----------|
| UI | Flutter (Material), go_router |
| Состояние | flutter_riverpod |
| Облако | Firebase Auth / Firestore / App Check / Crashlytics |
| Локально | shared_preferences, flutter_secure_storage |
| Документы | pdf, printing, excel, share_plus |

## Структура проекта

```
lib/
  app/         — точка входа приложения: тема, DI, роутинг
  core/        — локализация, генерация PDF
  features/    — фичи (каждая с data / domain / presentation)
  shared/      — общие модели и виджеты
test/          — юнит-тесты
firestore.rules — правила доступа к Firestore (деплой вручную или через Firebase CLI)
```

## Запуск

1. Установите Flutter (Dart SDK `>=3.0.0 <4.0.0`).
2. Склонируйте репозиторий и установите зависимости:
   ```bash
   flutter pub get
   ```
3. Для облачной синхронизации добавьте свой `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) от вашего Firebase-проекта. Без них приложение запустится и будет работать офлайн.
4. Опубликуйте `firestore.rules` в Firebase Console → Firestore → Rules, иначе база останется в test/locked mode.
5. Запуск:
   ```bash
   flutter run
   ```

## Проверка качества

```bash
flutter analyze   # статический анализ
flutter test      # юнит-тесты
```

Оба шага также выполняются автоматически в GitHub Actions на каждый push и PR.
