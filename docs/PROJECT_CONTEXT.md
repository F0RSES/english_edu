# Project Context

Шаблон состояния проекта. Обновляется в конце каждой задачи. Плейсхолдеры `<...>` заполняются по факту.

## Phase
25a закрыта (Chat with AI bot, ADR-041 Proposed). Схема v15, 16 таблиц; 836 тестов (116 файлов), 40 ADR. Следующая: 24 (QA-проход).

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
- Phase 5, task 5c — Локальные напоминания (ADR-017): `flutter_local_notifications` 22.3.3, desugaring + multiDex, `NotificationService` + NoOp, tz init в `bootstrapApp`, переключатель и выбор времени в `ProfileScreen`; `flutter build apk --debug` — успех. **BL-38 Done.**
- Phase 5, task 5d — Freeze system (ADR-015 Accepted): `frozen_days` + `schemaVersion 2` (миграция v1→v2 под тестом), `StreakRule` (7/30), `ComputeStreak` учитывает заморозки, `MarkMissedDay` в `bootstrapApp`, `StreakCard` показывает остаток и бейдж; BL-46 Done (385 tests).
- Phase 7–12 — AI-подсказки (ADR-019, схема v4 `word_hints`), Error Hunter (ADR-020), аналитика (ADR-021), UI/UX overhaul, онбординг-гейт, релизная подпись; Phase 12 — облачная синхронизация прогресса через Supabase (ADR-022): `CloudSyncService`/`CloudAuthService` в domain, `lib/data/sync/` с merge по `updatedAtUtc`, секция «Синхронизация» в профиле; ключи только через `--dart-define` (513 tests).
- Phase 13a — CEFR-градация (ADR-023): `CefrLevel` (A0–C2), `Word.level` и `UserSettings.preferredLevel`, схема v6 (`words.level`, `user_settings.preferred_level`), фильтр `newWords` по уровню (due — без фильтра), выбор уровня в онбординге и профиле, фильтр и бейдж уровня в словаре (534 test).
- Phase 13b — BL-67: `ExportPayload` v4 с `Word.level` (снимки v1–v3 читаются с A1), выбор уровня в `AddWordDialog` (544 test). **BL-67 Done.**
- Phase 13c–13e — контент и упаковка: генератор берёт уровень из списка (`term,level`), чистит `partOfSpeech`; `tools/merge_seeds.dart` слил 2796 записей в 2071 уникальное слово (`assets/seed/words_v2.json`, уровни A1–C1), `JsonSeedLoader` читает слитый файл, в APK попадает только он; ExportPayload **v5** с `UserSettings.preferredLevel` (564 test). **BL-68 Done.**
- Phase 13f — защита от дубликатов (ADR-024): `findByTerm`, диалог «Перейти» в `AddWordDialog`, дедупликация в `ExportPayloadCodec.decode` (574 test).
- Phase 14a — игра «Заполни пропуск» (ADR-025): `ClozeTask`, `AiClient.generateCloze`, кэш `cloze_tasks` (схема v7), `GetClozeTask`, экран `/cloze-test` (643 test).
- Phase 14c — повторение сложных слов (ADR-026): `GetWeakWordsQueue` (lapses > 0 или ease < 2.0), `LessonMode.weak` в `LessonScreen`, маршрут `/weak-words`, кнопка «Повторить сложные (N)» с бейджем (643 test).
- Phase 14d — игра «Собери слово» (ADR-027): `ScramblePuzzle`, `GenerateScramblePuzzles` (офлайн, без AI), `/word-scramble`, кнопка на главном (643 test).
- Phase 14e — аудио-диктант (ADR-028): `GenerateDictationQueue`, TTS-озвучка, `RecordReview` в диктанте и Scramble — **BL-71 Done**, BL-72 в бэклоге (643 test).

## In progress
- — (MVP ready)

## Next
- Phase 6c — проверка напоминаний на реальном устройстве, iOS delegate (нужен macOS), BL-53 (exact alarms) по жалобам.
- Phase 5e — streak continuity и защита от эксплойта freeze (BL-50).
- Phase 7 — публикация, решение пользователя.
- Phase 13 — расширение облака на логи/статистику/заморозки (BL-62) и инкрементальный `pull` (BL-63).
- Ревью машинных переводов: 2031 слово с `autoTranslated: true` (BL-21), разметка A0/C2 (BL-65); UI/text polish (BL-66).

## Open questions
- APK build: `flutter build apk --debug` собран (Android SDK 36, JDK 25) — BL-48 закрывается проверкой release-сборки на CI.
- iOS build: нужен macOS; `sentry_flutter` 10.x работает через SPM, `Podfile` не создаётся.
- License: не выбрана (BL-08); в README остался плейсхолдер `<your-email>` — заменить перед публикацией.
- DSN для release: нужен проект в Sentry (ADR-016), без него crash reporting выключен.
- Миграции v1→v15 покрыты тестами; откат (даунгрейд) не поддерживается — БД forward-only (стандарт для мобильных).
- BL-51 закрыт: заморозки входят в export/import (schemaVersion 2) и очищаются сбросом прогресса; снимки v1 читаются с пустым `frozenDays`.
- Напоминания проверены только сборкой: реальное срабатывание и iOS delegate — Phase 6c.
- Облако проверено тестами и сборкой APK: реальный проект Supabase, RLS и magic link на устройстве не прогонялись (нужны ключи проекта).

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
- Документация приведена к коду (15a-fix): ARCHITECTURE (схема v7, 8 таблиц, `ExportPayload` v5, Non-goals), ADR-016 дата, статусы BL-01/02/04/05/06/07.
- Ручной QA-проход по устройству — `docs/QA_CHECKLIST.md` (автотесты не покрывают TTS, уведомления, темы и железо).
- Отключены 4 линта анализатора 3.13.7 (ADR-007), уборка — BL-28.

- Host: Dart 3.13.4 stable, linux_x64.
- <проблема> — <обходной путь> — <ID задачи>

## Технический долг
- <долг> — <ID задачи>
