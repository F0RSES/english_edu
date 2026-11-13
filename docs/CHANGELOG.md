# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версионирование — SemVer, вводится в Phase 2 вместе с первой сборкой.
Разделы внутри версии: Added / Changed / Deprecated / Removed / Fixed / Security.

## [Unreleased]

### Added
- `.gitignore` — артефакты сборки и IDE, `pubspec.lock` намеренно не игнорируется.
- Seed-пайплайн: `assets/seed/words_v1.json` (20 слов), `tools/validate_seed_lib.dart`, `tools/validate_seed.dart`, `docs/SEED_FORMAT.md`, BL-21.
- `tools/generate_seed.dart` — генератор контента через DeepSeek; `docs/LICENSE_CONTENT.md`; поле `autoTranslated`; BL-24, BL-25.
- Flutter bootstrap: `flutter create` (android/ios), ADR-006, ADR-007, `drift_flutter ^0.3.1`, `flutter_riverpod ^3.4.3`, `go_router ^18.1.3`, `flutter_local_notifications ^22.3.3`; BL-26–BL-28.
- Drift schema v1: 5 таблиц (`words`, `word_progresses`, `review_logs`, `user_settings`, `daily_stats`), `AppDatabase`, `app_database.g.dart`, 5 индексов, `PRAGMA foreign_keys = ON` в `beforeOpen`, smoke-тест на 6 сценариев.
- Мапперы domain↔data: `WordMapper`, `CardStateMapper`, `WordProgressMapper`, `ReviewLogMapper`, `UserSettingsMapper`, `DailyStatsMapper`; `SeedLoader`/`JsonSeedLoader`; ADR-008; BL-30, BL-31.
- Реализации репозиториев: `DriftWordRepository`, `DriftProgressRepository`, `DriftReviewLogRepository`, `DriftSettingsRepository`, `DriftStatsRepository`; `WordRepository.insertMany`; seed loader через `WordRepository` (транзакция); BL-31 закрыт, BL-32.
- DI: `lib/core/di/providers.dart` (14 провайдеров), `NextReviewLogIdGenerator`, `main.dart` с bootstrap (DB → seed → max-id → runApp), ADR-009; `WordRepository.count()`; BL-33–BL-35. BL-03 закрыт — Phase 2a завершена.
- `assetBundleProvider` для подмены seed-бандла в тестах; `bootstrapApp` вынесен в тестируемую функцию; BL-36.
- LessonScreen + сессия: `router.dart`, `theme.dart`, 4 экрана, `WordCard`, `SessionSummary`; `UndoLastReview` + `ReviewLogRepository.delete` (ADR-010); BL-37.
- `Logger`/`DebugLogger`, `XpRules`, `ReviewOutcome`; `RecordReview` возвращает результат (ADR-011); undo откатывает `DailyStats`; `confirmDismiss` у карточки.
- TTS: `TtsService`/`FlutterTtsService`, `ttsProvider`, кнопка озвучки в `WordCard`, TTS-блок в `ProfileScreen`; `flutter_tts ^4.2.5`; `<queries>` TTS_SERVICE в манифесте; ADR-012; BL-38.
- Dictionary: `DictionaryEntry`, `dictionaryEntriesProvider`/`dictionarySearchQueryProvider`, `DictionaryScreen` (поиск через контракт, вкладки), `WordListItem`, `AddWordDialog`; тест error-состояния `ProfileScreen`.
- `WordRepository.nextId()` — `SELECT COALESCE(MAX(id), 0) + 1` одним запросом; `AddWordDialog` больше не читает `getAll()` ради id. Атомарность при параллельных вставках — Phase 5 (BL-39).
- `HomeScreen`: `StreakCard`, `DailyGoalCard`, `NavigationBar` (Главная / Словарь / Профиль); старт урока заблокирован при пустой очереди, ошибка очереди даёт «Повторить». Долг по кэшу future — BL-41.
- `DailyGoal` (VO) — «сделано / план» из `DailyStats` и суммы лимитов; `dailyGoalProvider` собирает его параллельным чтением статистики и настроек.
- Плюрализация streak: «1 день», «2 дня», «5 дней», «11 дней».
- `ResetProgress` (ADR-013) + danger-zone в `ProfileScreen`: подтверждение, очистка прогресса/логов/статистики, инвалидация четырёх провайдеров.
- `ExportPayloadCodec` (data, схема v1) + `payloadCodecProvider`; `ExportDialog` и `ImportDialog` через clipboard (ADR-014), без внешних пакетов.
- `ProfileScreen`: дневные лимиты (`dailyNewLimit` 0..50 шаг 5, `dailyReviewLimit` 0..200 шаг 10), резервная копия, опасная зона.
- `LessonScreen`: `PopScope` — системный back инвалидирует кэш главного экрана; подтверждение для недоделанной сессии отложено (BL-43).
- `pluralize` (`lib/core/text/plural.dart`) — русское склонение по числу; используется в `StreakCard` и кнопке старта урока (BL-45 закрыт).
- `StreakCard`: крупная цифра серии, остаток до вехи 7, поздравления на 7/30/100/365, подпись «Freeze появится в Phase 5d».
- BL-43: `PopScope(canPop: !_hasProgress)` + диалог «Завершить сессию?»; при подтверждении кэш инвалидируется и экран закрывается.
- Sentry crash reporting (ADR-016): `sentry_flutter ^10.3.0`, `lib/core/crash_reporter.dart` (`CrashReporter`, `SentryCrashReporter`, `NoOpCrashReporter`), `crashReporterProvider`.
- `bootstrapApp` принимает `sentryDsn` и `sentryInit` и возвращает `({idGenerator, crashReporter})`; DSN — только через `--dart-define=SENTRY_DSN`, пустой → `NoOpCrashReporter`.
- Отправка сбоев из `LessonScreen._grade` (`record_review`) и `ImportDialog._submit` (`import`).
- BL-47 (performance traces, P3), BL-48 (`jni`/NDK на первой APK-сборке, P2).
- Локальный CI: `scripts/ci.sh` (format + analyze + test) и `scripts/README.md`.
- BL-49 (P3): защита UI от падения `captureException`.
- Freeze system (ADR-015): таблица `frozen_days` (`dateEpochDays` PK, `consumedAtUtc`, `reason`), `FrozenDays` в `@DriftDatabase`, `schemaVersion 1 → 2` с миграцией `onUpgrade` (только `createTable`, данные v1 сохраняются).
- `StreakRule` (`frozenEarnedFor`: 7/30, `maxAvailable = 2`), `FrozenDaysRepository` + `DriftFrozenDaysRepository`.
- `MarkMissedDay` + покрытие вчерашнего пропуска в `bootstrapApp` (считается серия на конец дня перед пропуском).
- BL-50 (streak continuity, P3).
- `ExportPayload` v2: `+ frozenDays` (`Set<LocalDate>`), `currentSchemaVersion = 2`; обратная совместимость — снимок v1 читается с пустым `frozenDays`.
- `ExportPayloadCodec`: `encode` пишет `frozenDays` (`daysSinceEpoch`), `decode` принимает v1 (пусто) и v2 (восстанавливает), версия 3+ — `FormatException`.
- Заморозки входят в export/import и очищаются сбросом прогресса. **BL-51 закрыт.**
- Локальные напоминания (ADR-017): `flutter_local_notifications ^22.3.3`, `timezone ^0.11.2`, `flutter_timezone ^5.1.1`.
- `lib/core/notifications/notification_service.dart` — `NotificationService`, `FlutterNotificationService`, `NoOpNotificationService`; `notificationServiceProvider` (override в `main`).
- `bootstrapApp`: инициализация таймзон (`initializeTimeZones` + `setLocalLocation`), инициализация плагина с fallback на NoOp и перепланирование напоминания при старте, если оно включено. `BootstrapResult` получил `notificationService`; тесты инжектят `notificationServiceBuilder`.
- `ProfileScreen`: рабочий переключатель напоминаний и выбор времени; разрешение спрашивается при включении, ошибка планирования показывает snackbar и не сохраняет настройку.
- **BL-38 закрыт**, BL-53 (exact alarms, P3).

### Fixed
- README: количество ADR исправлено с 6 на 16 (фактически ADR-001…ADR-016).
- BL-41: `computeStreakProvider` / `getTodayQueueProvider` переведены в `FutureProvider` (UseCase-провайдеры переименованы в `computeStreakUseCaseProvider` / `getTodayQueueUseCaseProvider`). `HomeScreen` использует `AsyncValue.when` вместо `FutureBuilder`, `LessonScreen` инвалидирует серию, очередь и цель после сессии и при закрытии — главный экран видит прогресс сразу после урока.
- ADR-001 «Core stack» — Accepted.
- ADR-002 «Persistence: Drift vs Isar» — Accepted.
- ADR-003 «Domain layer location» — Accepted.
- `pubspec.yaml` — dev-only, без Flutter SDK.
- `analysis_options.yaml` — very_good_analysis + strict-* и кастомные правила.
- `docs/ARCHITECTURE.md` — карта контрактов домена.
- `.clinerules/30-workflow.md` — DoD уточнён: tooling прогоняется на хосте, отчёт обязан содержать вывод.
- `meta` в `dependencies` — аннотации `@immutable` на 5 value objects, рантайм-кода нет.
- `TodayQueue` VO; 5 repository interfaces (`Word`, `Progress`, `ReviewLog`, `Settings`, `Stats`); BL-12.
- ADR-004 «WordStatus source of truth»; `WordRepository.getByIds`; BL-13.
- `ComputeStreak` и `GetTodayQueue`; in-memory fakes репозиториев в `test/domain/usecases/fakes/`.
- `SrsCalculator`, `RecordReview`, `ExportProgress`, `ImportProgress`, `ExportPayload`; fakes `FakeSrsCalculator`, `FakeReviewLogRepository`.
- `Sm2SrsCalculator` — реализация SM-2 с 4-уровневой градацией.
- Интеграционные тесты `RecordReview` + реальный `Sm2SrsCalculator`; BL-17, BL-18.
- Многошаговый тест SM-2 (1/6/15/38/95, mastered на пятом ответе); BL-19, BL-20.
- Тест «слово с двумя провалами достигает mastered».
- `clear()` в четырёх репозиториях — требование REPLACE-импорта.
- `getAll()` в `ProgressRepository`, `ReviewLogRepository`, `StatsRepository`; ADR-005; BL-16.
- `StatsRepository.getLastActiveDate`.

### Changed
- Android: `compileSdk = 36` литералом (было `flutter.compileSdkVersion`), включены `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs 2.1.4` и `multiDexEnabled`.
- Манифест: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver` и `ScheduledNotificationBootReceiver` (`exported="false"`); `SCHEDULE_EXACT_ALARM` намеренно не добавлен.
- `ExportProgress`, `ImportProgress` и `ResetProgress` принимают `FrozenDaysRepository`; импорт дописывает шаг `frozen.replaceAll`, сброс — `frozen.replaceAll(const [])` (порядок progress → logs → stats → frozen).
- `ImportProgress` валидирует версии `1..2` вместо только `1`; `ImportDialog` пропускает обе версии, версия 3+ отсекается кодеком («Невалидный JSON»).
- `StreakInfo`: `+int frozenAvailable`, `+Set<LocalDate> frozenDates`; оба поля участвуют в `==`/`hashCode`, множество сравнивается без `setEquals` (domain — pure Dart).
- `ComputeStreak` принимает `FrozenDaysRepository`: замороженный день продолжает серию и входит в счёт, `frozenAvailable = clamp(earned(count) - frozen.length, 0, 2)`; 3 запроса вместо 2.
- `StreakCard` требует `today` и показывает остаток заморозок и бейдж «Freeze использован» (вместо «Freeze появится в Phase 5d»); `HomeScreen` передаёт локальную дату из `clockProvider`.
- **BL-46 закрыт**, ADR-015 — Accepted.
- `dart format` применён ко всему репозиторию: 73 файла, только переносы строк и trailing commas, analyze=0, 355 тестов зелёные. **BL-40 закрыт.**
- README переписан: финальный статус MVP, инструкция для бета-тестеров, Sentry, Roadmap.
- DoD дополнен прогоном `bash scripts/ci.sh` перед коммитом.
- `minSdk` 24 → 26 (Android 8.0) — требование `sentry_flutter` 10.x; `compileSdk`/`targetSdk`/`ndkVersion` не менялись.
- `bootstrapApp` возвращает запись `({NextReviewLogIdGenerator idGenerator, CrashReporter crashReporter})` вместо одного генератора.
- Тулинг: `dart analyze` / `dart test` → `flutter analyze` / `flutter test`.
- `environment` без flutter-констрейнта, `sdk: ">=3.13.0 <4.0.0"`; `test ^1.31.1` (пин `test_api 0.7.12` от Flutter), `build_runner ^2.16.1`.
- `analysis_options.yaml`: отключены 4 линта анализатора 3.13.7 (ADR-007, BL-28).
- ADR-007: детализированы 4 lint exceptions; аудит 2a.0c опроверг риск с именами параметров у `prefer_initializing_formals` — 24 срабатывания в 5 файлах `lib/domain/usecases/`, автофикс безопасен.
- BL-28: поднят до P2, расписан по каждому из 4 правил.
- `assert(isUtc)` → `ArgumentError` в `WordProgress`, `ReviewLog`, `Sm2SrsCalculator`: проверка release-safe, тихая ошибка TZ заменена исключением.
- `getDueBefore` и `getByDateRange`: dartdoc требует `ArgumentError` от реализации вместо assert.
- `RecordReview._deriveStatus`: после любого ответа — минимум `learning`; `newWord` только до первого ответа.
- `SEED_FORMAT.md`: описаны `autoTranslated` и правила хранения (`term` в нижнем регистре, капитализация — UI).
- BL-21 переформулирован: план «autoTranslated → verified», а не расширение объёма.
- Правило mastery: `reps >= 5 && intervalDays >= 21` вместо `reps >= 5 && lapses <= 1` — устраняет вечный блок для слов с 2+ провалами.
- `clear()` → `replaceAll(Iterable<…>)` в четырёх репозиториях: атомарная замена вместо «очистить и вставить по одному».
- `.clinerules/10-project.md`, `README.md` — синхронизированы с ADR-002.
- `README.md` — Status переведён в Phase 1, ссылка на ADR-001 обновлена на Accepted.
- `.clinerules/10-project.md` — возвращена строка про миграции схемы, TZ-вопрос заменён ссылкой на ADR-001.
- ADR-002 — Verification gate формализован (критерий unmaintained).
- BL-01 — критерий приёмки переписан под код контрактов.
- `very_good_analysis` и `test` — версии приняты по pub.dev, перепроверка в 1.1a.
- `docs/PROJECT_CONTEXT.md` — `lib/` и `test/` отнесены к Phase 1 (ADR-003).
- `docs/ARCHITECTURE.md` — добавлен раздел Non-goals.
- `LocalDate.fromDateTime` и `today` — без неявного `.toLocal()`, тесты TZ-независимы.
- `.clinerules/20-code-style.md` — freezed только для Riverpod state.
- `.clinerules/30-workflow.md` — шаг 5 приведён к Definition of Done.
- ADR-003 — runtime-зависимости уточнены: `meta` (annotations only), иных нет; LocalDate вынесен отдельным подпунктом.
- `.clinerules/20-code-style.md` — правило freezed разбито на два пункта (state vs entities/VO).
- Добавлены entities + `WordStatus`; `WordProgress` и `ReviewLog` — non-const конструкторы (assert на `DateTime.isUtc`).
- `Serialization contract` — запрет сериализации enum по `.index`; BL-11 получил измеримый trigger.
- ARCHITECTURE — 5 интерфейсов вместо 3; `search` описан как term OR translation.
- `ComputeStreak` — `_lookbackDays` 366 → 3650.
- ARCHITECTURE — таблицы `Word` и `SettingsRepository` приведены к коду, путь `lib/domain/usecases/`.

### Verified
- [host] 1.1a.0: Dart 3.13.4 stable, linux_x64.
- [host] 1.1a.0: `dart pub get` — resolved 50 dependencies (very_good_analysis 11.0.0, test 1.33.0).
- [host] 1.1a.0: `dart analyze` — 0 issues.
- [host] 1.1a.0: `dart format .` — 0 files changed, baseline зафиксирован.
- [host] 1.1a.0: `pubspec.lock` создан и не игнорируется.
- [sandbox] 1.1a.1: `dart analyze` — 0 issues.
- [sandbox] 1.1a.1: `dart test` — 44 passed.
- [sandbox] 1.1a.2: `dart analyze` — 0 issues.
- [sandbox] 1.1a.2: `dart test` — 86 passed.
- [sandbox] 1.1a.2: `dart format` — 0 changed.
- [sandbox] 1.1b.0: `dart analyze` — 0 issues.
- [sandbox] 1.1b.0: `dart test` — 95 passed.
- [sandbox] 1.1b.0b: `dart analyze` — 0 issues.
- [sandbox] 1.1b.0b: `dart test` — 95 passed.
- [sandbox] 1.1b.1: `dart analyze` — 0 issues.
- [sandbox] 1.1b.1: `dart test` — 109 passed.
- [sandbox] 1.1b.1b: `dart analyze` — 0 issues.
- [sandbox] 1.1b.1b: `dart test` — 114 passed.
- [sandbox] 1.1b.2: `dart analyze` — 0 issues.
- [sandbox] 1.1b.2: `dart test` — 134 passed.
- [sandbox] 1.1b.2b: `dart analyze` — 0 issues.
- [sandbox] 1.1b.2b: `dart test` — 136 passed.
- [sandbox] 1.1c: `dart analyze` — 0 issues.
- [sandbox] 1.1c: `dart test` — 152 passed.
- [sandbox] 1.1c.1: `dart analyze` — 0 issues.
- [sandbox] 1.1c.1: `dart test` — 156 passed.
- [sandbox] 1.1c.2: `dart analyze` — 0 issues.
- [sandbox] 1.1c.2: `dart test` — 158 passed.
- [sandbox] 1.1c.2b: `dart analyze` — 0 issues.
- [sandbox] 1.1c.2b: `dart test` — 161 passed.
- [sandbox] 1.2a: `dart analyze` — 0 issues.
- [sandbox] 1.2a: `dart test` — 169 passed.
- [sandbox] 1.2a: `dart run tools/validate_seed.dart assets/seed/words_v1.json` — `OK: 20 words, 1 source, 0 warnings`, exit 0.
- [sandbox] 1.2b: `dart analyze` — 0 issues.
- [sandbox] 1.2b: `dart test` — 171 passed.
- [sandbox] 1.2b: `dart run tools/validate_seed.dart assets/seed/words_v1.json` — `OK: 20 words, 1 source, 0 warnings`.
- `generate_seed.dart` не запускался: в sandbox нет сети и нет `DEEPSEEK_API_KEY`.
- [sandbox] 2a.0a: `dart analyze` — 0 issues.
- [sandbox] 2a.0a: `dart test` — 173 passed.
- [sandbox] 2a.0a: `dart run tools/validate_seed.dart assets/seed/words_v1.json` — `OK: 20 words, 1 source, 0 warnings`.
- [sandbox] 2a.0b: `flutter --version` — Flutter 3.47.9 stable, Dart 3.13.7, linux_x64.
- [sandbox] 2a.0b: `flutter pub get` — 127 packages in `pubspec.lock`.
- [sandbox] 2a.0b: `flutter analyze` — No issues found!
- [sandbox] 2a.0b: `flutter test` — 174 passed.
- Note 2a.0c: 174 tests, `flutter analyze` = 0 issues с 4 отключёнными правилами (ADR-007, BL-28).
- [sandbox] 2a.1: `flutter analyze` — 0 issues.
- [sandbox] 2a.1: `flutter test` — 180 passed.
- [sandbox] 2a.1: `dart run build_runner build` — `app_database.g.dart` 147K, 5 индексов в схеме.
- [sandbox] 2a.2a: `flutter analyze` — 0 issues.
- [sandbox] 2a.2a: `flutter test` — 202 passed.
- [sandbox] 2a.2b: `flutter analyze` — 0 issues.
- [sandbox] 2a.2b: `flutter test` — 240 passed.
- [sandbox] 2a.2c: `flutter analyze` — 0 issues.
- [sandbox] 2a.2c: `flutter test` — 245 passed.
- [sandbox] 2a.2d: `flutter analyze` — 0 issues.
- [sandbox] 2a.2d: `flutter test` — 249 passed.
- [sandbox] 3a: `flutter analyze` — 0 issues.
- [sandbox] 3a: `flutter test` — 265 passed.
- [sandbox] 3a.1: `flutter analyze` — 0 issues.
- [sandbox] 3a.1: `flutter test` — 270 passed.
- [sandbox] 3b: `flutter analyze` — 0 issues.
- [sandbox] 3b: `flutter test` — 278 passed.
- [sandbox] 4a: `flutter analyze` — 0 issues.
- [sandbox] 4a: `flutter test` — 297 passed.

### Deprecated

### Removed
- `Word.status` — статус перенесён в `WordProgress` (ADR-004).
- `WordRepository.getByStatus`.
- `sqlite3_flutter_libs` и `path_provider` — заменены на `drift_flutter` (транзитивно тянет нужное).
- `flutter_lints` — достаточно very_good_analysis.

### Fixed
- BL-01 ошибочно закрыт до завершения 1.1 → In progress.
- `main.dart`: падение seed-загрузчика больше не блокирует запуск — `try/catch` с логом, приложение стартует с пустой БД.
- `README.md`: статус «Phase 2a — Flutter bootstrap (174 tests, analyze=0)», рабочий раздел How to run и Environment вместо заглушек.
- `generate_seed.dart`: таймауты connect 30s / idle 60s; в сообщения об ошибке попадают только статус и первые 200 символов ответа.
- `validate_seed`: убрано warning о дублях `frequencyRank` — ранг уникален только в пространстве `sourceId`.
- `RecordReview` после провала возвращал статус `newWord` (слово уже видели) — теперь `learning`.
- ARCHITECTURE: раздел `SRS` указывает реальную реализацию `Sm2SrsCalculator` и формулу.
- `ComputeStreak` использовал UTC-дату, `RecordReview` пишет локальную — streak не видел сегодняшнюю активность при TZ ≠ UTC; теперь обе стороны используют `clock().toLocal()`.
- Экспорт терял логи, созданные в тот же миг, что и снимок (`getByDateRange` — полуинтервал); теперь `getAll`.
- ARCHITECTURE.md синхронизирован с кодом: таблицы `WordProgress`, `ReviewLog`, `UserSettings`, `DailyStats`, `CardState`, `StreakInfo` и сигнатуры `GetTodayQueue`/`ComputeStreak`; BL-14, BL-15.
- Дубли due/new в `GetTodayQueue` — слова со статусом `newWord` исключены из `due`.
- `ComputeStreak` — вместо запроса на каждый день теперь 2 запроса независимо от истории.
- 10 analyzer issues `avoid_equals_and_hash_code_on_mutable_classes` закрыты через `@immutable`.
- ADR-003 — удалена устаревшая гипотеза про несовместимость SDK (опровергнута прогоном на Dart 3.13.4).
- ADR-001 — добавлен пункт (e): effective minimum Dart SDK 3.13.

### Security
