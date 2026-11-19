# Project Context

Шаблон состояния проекта. Обновляется в конце каждой задачи. Плейсхолдеры `<...>` заполняются по факту.

## Phase
46 закрыта (Принудительный Markdown от ИИ + отступы Drawer). Схема v23, 19 таблиц; 1181 тест, 47 ADR (ADR-046/047 Proposed). Следующая: по плану владельца.

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
- Phase 15–30 — daily challenge, challenge streak, smart review, категории, 30 достижений, игры (memory, typing, phrasebook, reading), облако Supabase, чат (ADR-041), error helper (ADR-042), RU/EN локализация UI (ADR-043), аватар/никнейм (ADR-044), Cloze UX (5 вариантов, bulk-лист) — подробно в docs/CHANGELOG.md.
- Phase 31 (BL-94 Done) — локализация внутренностей 12 экранов: 65 ключей `S` (ru/en), EN-тесты каждого экрана, плюрализация `readingWordUnit` (972 теста).
- Phase 32 — сброс устаревшего кэша `cloze_tasks`: миграция v19 (обновлён AI-промпт Worker), 973 теста.
- Phase 33 — BL-95 (доки приведены к коду), ADR-041/042/043/044 → Accepted, BL-96 (кэш переводов `word_translations`, схема v20, `TranslateWord`): 984 теста.
- Phase 34 — главный экран: секции «Обучение» и «Тренировки» с заголовками, hero и Weak/Smart сохранены (987 тестов).
- Phase 35 — Sentence Builder: порядок слов, офлайн из `exampleSentence`, AI-fallback `sentence_builder`, сессия 5 предложений (1014 тестов).
- Phase 36a — Typing Speed: `Word.synonyms` (схема v21), подсказка «4 буквы, m...», общий `SubmitTypingAnswer.matches`; `meal` ↔ `food` в seed (1026 тестов).
- Phase 36b — Listening v2: аудио-диктант предложений (TTS, перевод-подсказка, нормализация ответа, сессия 5); сетка «Обучения» 2×2 — роадмап игр закрыт (1042 теста).
- Phase 37a — полная синхронизация доков к v1.32.0-beta (README, PROJECT_CONTEXT, ARCHITECTURE, BACKLOG).
- Phase 38f — SeedLoader переведён на `assets/seed/words_v3.json`: 7416 слов (A0–C2), 5 источников; v2 остаётся в репозитории базой для tools, из APK убран. ci.sh зелёный (1042 теста), apk --debug собран.
- Phase 42 — История чатов DeepSeek-style (ADR-046 Proposed): схема v23 (`chat_sessions` + `chat_messages.session_id` FK cascade, миграция с backfill старых сообщений в дефолтную сессию), `ChatSession`/`ChatSessionRepository`/`ChatSessionGroup`, drawer с группами Сегодня/Вчера/Последние 7 дней/Старые + Закреплённые, переименование/закрепление/удаление через bottom sheet, автосоздание сессии при первой отправке (title — 30 символов), восстановление последнего диалога при открытии; аватар пользователя в пузырях (`UserAvatar`: файл профиля → инициалы → иконка). BL-98 Done.
- Phase 43 — Полировка истории чатов (ADR-046): скругление плиток radius 12 (`ListTile.shape` → `InkWell.customBorder`), multi-select по long-press (хедер «Выбрано: N», bulk-удаление с подтверждением и плюрализацией, check_circle/radio_button_unchecked, «Новый чат» скрыт в режиме выбора); BottomSheet только по «трём точкам». BL-99 Done.
- Phase 44 — Фиксы UI истории чатов и ребрендинг (ADR-046): SafeArea снаружи Drawer (панель целиком ниже статус-бара), явный вход в multi-select (checklist в хедере, пустой набор), AppBar без аватара бота; бот — «Маффин»/«Muffin» (ключи assistant/explain/helper.ask/aiHelper.title/chat.greeting, приветствие представляется). BL-100 Done.
- Phase 45 — Markdown-рендеринг ответов ИИ (ADR-047 Proposed): `flutter_markdown_plus ^1.0.12` (+markdown 7.3.1), виджет `AssistantMarkdown` (тема: onSurface, код surfaceContainerHighest + radius 12, списки, GFM-таблицы), user-сообщения остаются Text; длинные строки кода — горизонтальный скролл без Overflow. BL-101 Done.
- Phase 46 — Принудительный Markdown от ИИ (ADR-047): системный промт первым сообщением каждого запроса чата (константа в AiClient, транспорт); contentPadding плитки drawer 16/4 в обоих режимах. BL-102 Done.

## In progress
- Подготовка к Google Play (Phase 37b: QA и релиз).

## Next
- Сбор фидбэка, иконка, Privacy Policy.
- Остальные улучшения — BACKLOG (P2/P3).

## Open questions
- Release QA: ручной проход на реальном устройстве (`docs/QA_CHECKLIST.md`) — TTS, уведомления, темы, переключение RU/EN, новые игры.
- Store listing: лицензия кода и support email (BL-08), Privacy Policy, иконка, Sentry DSN для release (ADR-016).

## Environment
- Flutter 3.47.9 (stable), Dart 3.13.7, linux_x64.
- Словарь: 7415 слов (A0: 67, A1: 747, A2: 1933, B1: 1821, B2: 1504, C1: 832, C2: 491); seed — `assets/seed/words_v3.json` (+20 базовых слов без level читаются как A1).
- Схема БД v21 (17 таблиц); 1042 теста (131 файл), analyze=0.
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

## Известные проблемы
- Документация синхронизирована с кодом в Phase 37a: схема v21 (17 таблиц), 1042 теста (131 файл), 43 ADR, ExportPayload v7, 19 экранов / 21 маршрут.
- Ручной QA-проход по устройству — `docs/QA_CHECKLIST.md` (автотесты не покрывают TTS, уведомления, темы и железо).
- Отключены 4 линта анализатора 3.13.7 (ADR-007), уборка — BL-28.

- Host: Dart 3.13.7 stable, linux_x64.

## Технический долг
- См. BACKLOG (P2/P3).
