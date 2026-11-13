# Project Context

Шаблон состояния проекта. Обновляется в конце каждой задачи. Плейсхолдеры `<...>` заполняются по факту.

## Phase
2 — Application shell

## Done
- Phase 0 — Bootstrap: 11 файлов управления проектом (`.clinerules/` + `docs/`).
- Phase 1, task 1.0 — ADR-001 и ADR-002 в статусе Accepted.
- Phase 1, task 1.1a.0 — toolchain verified on Dart 3.13.4; pubspec.lock committed.
- Phase 1, task 1.1a.1 — value objects (6 VO, 44 теста, analyze=0).
- Phase 1, task 1.1a.2 — entities (5) + WordStatus (86 tests, analyze=0).
- Phase 1, task 1.1b.0 — TodayQueue + 5 interfaces (95 tests).
- Phase 1, task 1.1b.1 — ComputeStreak + GetTodayQueue (114 tests).
- Phase 1, task 1.1b.2b — TZ fix + replaceAll/getAll + ADR-005 (136 tests).
- Phase 1, task 1.1c — Sm2SrsCalculator (152 tests).
- Phase 1, task 1.1c.1 — release-safe проверки + связка RecordReview с SM-2 (156 tests).
- Phase 1, task 1.1c.2b — mastery fix: reps ≥ 5 && interval ≥ 21 (161 tests).
- Phase 1, task 1.2a — seed schema + validator + 20 слов (169 tests).
- Phase 1, task 1.2b — генератор контента + лицензии + `autoTranslated` (173 tests).
- **Phase 1 закрыта.**
- Phase 2, task 2a.0b — Flutter bootstrap: `flutter create`, ADR-006, ADR-007, 174 tests.
- Phase 2, task 2a.0c — README (статус, How to run, Environment) + аудит 4 отключённых линтов.
- Phase 2, task 2a.1 — Drift schema v1: 5 таблиц, `AppDatabase`, codegen, 6 smoke-тестов (180 tests).
- Phase 2, task 2a.2a — мапперы domain↔data + `JsonSeedLoader` (202 tests).
- Phase 2, task 2a.2b — 5 Drift-репозиториев, `insertMany`, seed loader через репозиторий (240 tests).
- Phase 2, task 2a.2c — Riverpod-провайдеры, `NextReviewLogIdGenerator`, bootstrap в `main` (245 tests). **Phase 2a завершена, BL-03 Done.**
- Phase 2, task 2a.2d — seed под try/catch, `assetBundleProvider`, тесты bootstrap (249 tests).
- Phase 3, task 3a — `LessonScreen` + сессия, router, theme, undo, ADR-010 (265 tests).
- Phase 3, task 3a.1 — `Logger`, `XpRules`, `ReviewOutcome`, undo откатывает stats, ADR-011 (270 tests).
- Phase 3, task 3b — TTS в `WordCard` и `ProfileScreen`, ADR-012 (278 tests). Notifications отложены.
- Phase 4, task 4a — `DictionaryScreen`: список, вкладки, поиск, добавление слова (297 tests).
- Phase 4, task 4a.1 — `WordRepository.nextId()` вместо `getAll().fold` (300 tests). BL-39 переформулирован: осталась атомарность.
- Phase 4, task 4b — `HomeScreen`: `StreakCard`, `DailyGoalCard`, `NavigationBar`, блокировка старта при пустой очереди (311 tests).
- Phase 4, task 4b.1 — `FutureProvider` для серии/очереди/цели, `ref.invalidate` после сессии, плюрализация streak (319 tests). **BL-41 Done.**
- Phase 4, task 4c — дневные лимиты, сброс прогресса (ADR-013), export/import через clipboard (ADR-014), `PopScope` в уроке (334 tests). **Phase 4 закрыта.**
- Phase 5, task 5a+5b — `PopScope` confirm (BL-43), общий `pluralize` (BL-45), визуал `StreakCard`; ADR-015 (freeze) — Proposed, без кода (347 tests).
- Phase 6, task 6a — Sentry: `CrashReporter`/`SentryCrashReporter`/`NoOpCrashReporter`, `crashReporterProvider`, DSN через `--dart-define`, `minSdk` 24 → 26; ADR-016 Accepted (355 tests).
- Phase 6, task 6b — `dart format` по всему репозиторию (BL-40), `scripts/ci.sh` (format + analyze + test), финальный README с инструкцией для бета-тестеров; тег `phase-6-mvp`. **Phase 6 закрыта** (без APK, iOS и reminders).

## In progress
- — (MVP ready)

## Next
- Phase 5c (notifications, нужен Android SDK) или Phase 7 (publish) — решение пользователя.

## Open questions
- APK build: Android SDK не установлен, `flutter build apk` не проверен (BL-38, BL-48).
- iOS build: нужен macOS; `sentry_flutter` 10.x работает через SPM, `Podfile` не создаётся.
- License: не выбрана (BL-08); в README остался плейсхолдер `<your-email>` — заменить перед публикацией.
- DSN для release: нужен проект в Sentry (ADR-016), без него crash reporting выключен.

## Environment
- Flutter 3.47.9 (stable), Dart 3.13.7, linux_x64.
- very_good_analysis 11.0.0; тулинг — `flutter analyze` / `flutter test`.
- Версии пакетов: ADR-007; pubspec.lock коммитится.

## Структура репозитория
- `.clinerules/` — правила работы в репозитории.
- `docs/` — контекст, ADR, бэклог, discovery, changelog.
- `lib/core/`, `lib/data/`, `lib/domain/`, `lib/presentation/` — слои приложения.
- `android/`, `ios/` — платформенные каталоги Flutter.
- `test/` — тесты домена, тулинга и виджет-тесты.
- `tools/` — генератор и валидатор seed.

## Ключевые файлы
- `docs/PROJECT_CONTEXT.md` — состояние проекта.
- `docs/DECISIONS.md` — ADR, архитектурные решения.
- `docs/BACKLOG.md` — задачи и критерии приёмки.
- `docs/ARCHITECTURE.md` — карта контрактов домена.
- `docs/SEED_FORMAT.md` — схема контента.
- `docs/CHANGELOG.md` — история изменений.

## Открытые вопросы
- TZ-пакет для расчёта streak — Phase 1.1 (не закрыт).
- License контента — BL-08, BL-21.
- <вопрос> — <кто и когда решает>

## Известные проблемы
- `flutter` не в PATH sandbox: вызывается по абсолютному пути `/home/norman/flutter/bin/flutter`.
- Отключены 4 линта анализатора 3.13.7 (ADR-007), уборка — BL-28.

- Host: Dart 3.13.4 stable, linux_x64.
- <проблема> — <обходной путь> — <ID задачи>

## Технический долг
- <долг> — <ID задачи>
