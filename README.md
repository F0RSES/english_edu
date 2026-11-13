# English Edu

Offline-first мобильное приложение для изучения английского
через интервальные повторения (SM-2).

## Status

**Phase 6 — MVP closed** (без reminders, без APK, без iOS —
см. Roadmap ниже). 355 тестов, analyze=0.

## Features

- Интервальные повторения (SM-2) с реальной моделью памяти
- Streak (серия дней)
- Swipe-карточки с TTS
- Личный словарь с поиском и добавлением
- Export/Import через clipboard
- Crash reporting (Sentry, опционально)
- Полностью offline-first

## Environment

- Flutter 3.47.9 (stable)
- Dart 3.13.7
- Android minSdk 26 / compileSdk 36
- iOS deployment target 15.0 (SPM, CocoaPods не поддерживается)

## How to run

    flutter pub get
    flutter run                # device/emulator
    flutter test               # 355 passed
    bash scripts/ci.sh         # CI

## Sentry (опционально)

DSN через --dart-define. Без DSN — NoOp.

    flutter build apk --dart-define=SENTRY_DSN=<url>

IP-адрес: отключить в Sentry Project Settings → Security & Privacy.

## Architecture

- Presentation (Flutter) → Domain (pure Dart) → Data (Drift)
- 6 ADR + архитектурные решения — docs/DECISIONS.md
- Contracts — docs/ARCHITECTURE.md
- Dependency versions — ADR-007

## Roadmap

- [x] Phase 1–6: architecture, data, LessonScreen, TTS,
      dictionary, settings, Sentry.
- [ ] Phase 5c: notifications (нужен Android SDK).
- [ ] Phase 6 APK build (нужен Android SDK).
- [ ] Phase 6 iOS build (нужен macOS).
- [ ] Phase 7: публикация (Google Play, App Store).
- [ ] Phase 8: AI-помощник (DeepSeek proxy).

## Тестирование беты

### Как сообщить о баге

1. Воспроизведите сценарий.
2. Сделайте screenshot или screen recording.
3. Отправьте: <your-email>.

### Известные ограничения

- Нет напоминаний (Phase 5c).
- Нет APK-сборки (нужен Android SDK у разработчика).
- iOS не собран (нет macOS).

### Что тестировать

- Пройти 10 карточек в уроке (свайп / кнопки).
- Добавить слово в словарь вручную.
- Export → сбросить прогресс → Import.
- Проверить streak (зайти 2 дня подряд).
- Сменить скорость TTS в ProfileScreen.

## License

Code: <не выбрана — BL-08>. Seed data: см. docs/LICENSE_CONTENT.md.
