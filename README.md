# English Edu

Мобильное приложение для изучения английского: карточки со словами, интервальное повторение по SM-2 и ежедневная короткая сессия. Работает offline-first — урок, повторение и прогресс не требуют сети; приложение помнит, что учить сегодня, и показывает честный прогресс по локальному времени. Цель MVP — довести пользователя до устойчивой ежедневной привычки, а не до каталога контента.

**Status:** Phase 6 — Sentry crash reporting (355 tests, analyze=0)

## Стек

| Слой | Технология |
|---|---|
| UI | Flutter 3.47.9 |
| State | flutter_riverpod 3.4.3 |
| Навигация | go_router 18.1.3 |
| Данные | drift 2.35.3 + drift_flutter 0.3.1 — см. ADR-002, ADR-006 |
| Модели | ручные `final class` + `@immutable` (без freezed для VO) |
| Речь | flutter_tts 4.2.5 |
| Уведомления | flutter_local_notifications 22.3.3 |
| Crash reporting | sentry_flutter 10.3.0 — см. ADR-016 |
| Линт | very_good_analysis 11.0.0 |

Версии зафиксированы в `docs/DECISIONS.md`, ADR-007 (Status: Accepted).

## Environment

- Flutter 3.47.9 (stable), Dart 3.13.7
- very_good_analysis 11.0.0 (4 rules disabled, see BL-28)
- drift 2.35.3 + drift_flutter 0.3.1
- flutter_riverpod 3.4.3

## Документация

- `docs/PROJECT_CONTEXT.md` — где сейчас проект.
- `docs/DECISIONS.md` — ADR.
- `docs/BACKLOG.md` — задачи и критерии приёмки.
- `docs/ARCHITECTURE.md` — карта контрактов домена.
- `docs/DISCOVERY.md` — интервью и гипотезы.
- `docs/CHANGELOG.md` — история изменений.

## How to run

Prereqs: Flutter 3.47.9+ / Dart 3.13.7+.

```bash
flutter pub get
flutter run                   # на устройстве/эмуляторе
flutter test                  # Tests: see CHANGELOG [Unreleased] Verified
flutter analyze               # 0 issues
```

Offline-first: приложение работает без сети. Seed-файл: `assets/seed/words_v1.json` (загрузка в 2a.2, BL-29).

## Environment variables

- `SENTRY_DSN` — опционально. Без него crash reporting отключён (`NoOpCrashReporter`), приложение работает как обычно.
- Для release: `flutter build apk --dart-define=SENTRY_DSN=<url>`.
- DSN не хранится в коде, `pubspec.yaml`, ассетах и git — только через `--dart-define`.
- IP-адрес: `sendDefaultPii: false` не отключает его сбор — отключите в Sentry Project Settings → Security & Privacy.

## Build requirements

- Android: `minSdk 26` (Android 8.0), `compileSdk 36`. `minSdk` поднят из-за `sentry_flutter` 10.x.
- iOS: deployment target 15.0, сборка через SPM (CocoaPods пакетом больше не поддерживается, `Podfile` не нужен).
- NDK: `ndkVersion` наследуется от Flutter (28.2.13676358); совместимость с `jni` проверяется на первой APK-сборке (BL-48).

## Лицензия

<не выбрана — решается до публикации, BL-08>
