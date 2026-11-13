# Architecture

Карта контрактов доменного слоя. Здесь описаны типы и сигнатуры; реализации появятся в 1.1a–1.1c.
Dart-код в документе не приводится: сигнатуры даны псевдо-Dart в backticks.

## Слои

- **presentation** — Flutter-виджеты и экраны, state через Riverpod. Зависит от domain.
- **domain** — сущности, value objects, контракты репозиториев, use cases. Pure Dart, без импортов Flutter.
- **data** — Drift-база (`drift` + `drift_flutter`) и реализации репозиториев. Зависит от domain.

Правило: presentation → domain ← data. Domain не импортирует ни presentation, ни data, ни Flutter.

Окружение: Flutter 3.47.9, Dart 3.13.7. Тулинг — `flutter analyze` / `flutter test`.

## Entities

### Word
Словарная статья: то, что показывается в карточке урока. Статуса изучения здесь нет — он принадлежит `WordProgress` (см. ADR-004).

| Поле | Тип | Назначение |
|---|---|---|
| id | `WordId` | Стабильный идентификатор слова в seed |
| term | `String` | Английский термин, уже trimmed и lower-case |
| translation | `String` | Перевод, русский |
| transcription | `String?` | IPA-транскрипция |
| partOfSpeech | `String?` | Часть речи, если известна |
| exampleSentence | `String?` | Пример употребления на английском |
| category | `String?` | Тематическая категория: «Бизнес», «IT», «Путешествия», «Быт»; null — без категории |

### WordProgress
Текущее состояние изучения слова: одна запись на слово. Конструктор non-const: assert на `DateTime.isUtc` не является potentially-constant выражением.

| Поле | Тип | Назначение |
|---|---|---|
| wordId | `WordId` | Ссылка на Word |
| cardState | `CardState` | Расписание повторений |
| status | `WordStatus` | Статус изучения — единственный источник истины (ADR-004) |
| firstSeenAt | `DateTime` | Первое появление в уроке, UTC (assert) |
| lastReviewedAt | `DateTime?` | Последняя оценка, UTC, null = не отвечали |

Фабрика `WordProgress.newWord({required WordId wordId, required DateTime now})` создаёт запись со статусом `newWord`, `CardState.initial(now)` и `firstSeenAt = now.toUtc()`.

### ReviewLog
Неизменяемая запись о попытке. Источник правды для статистики и streak. Конструктор non-const по той же причине, что у WordProgress. Append-only: без `copyWith`, записи не редактируются и не удаляются.

| Поле | Тип | Назначение |
|---|---|---|
| id | `ReviewLogId` | Идентификатор записи |
| wordId | `WordId` | Какое слово оценивали |
| reviewedAt | `DateTime` | Момент ответа, UTC (assert) |
| grade | `ReviewGrade` | Оценка: again / hard / good / easy |
| previousCardState | `CardState` | Состояние карточки до ответа |
| newCardState | `CardState` | Состояние карточки после ответа |

### UserSettings
Пользовательские настройки: одна запись на устройство. Фабрика `UserSettings.defaults()` возвращает все значения по умолчанию.

| Поле | Тип | Дефолт | Назначение |
|---|---|---|---|
| dailyNewLimit | `int` | 10 | Лимит новых слов в день, `>= 0` |
| dailyReviewLimit | `int` | 50 | Лимит повторений в день, `>= 0` |
| remindersEnabled | `bool` | false | Локальные напоминания включены |
| reminderHour | `int` | 9 | Час напоминания, `0..23` |
| reminderMinute | `int` | 0 | Минута напоминания, `0..59` |
| ttsVoice | `String` | 'en-US' | Идентификатор голоса TTS |
| ttsSpeed | `double` | 0.5 | Скорость речи, `0.1..1.0` |

### DailyStats
Агрегат по одному локальному дню. Вычисляется из ReviewLog, вручную не вводится. Фабрика `DailyStats.empty(date)` даёт нулевые счётчики. Геттеры: `totalAnswers = newWordsStudied + reviewsCompleted`, `accuracy = totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers` (приближение, точное определение — Phase 3).

| Поле | Тип | Назначение |
|---|---|---|
| date | `LocalDate` | День в локальной TZ пользователя |
| newWordsStudied | `int` | Новых слов показано, `>= 0` |
| reviewsCompleted | `int` | Повторений завершено, `>= 0` |
| xpGained | `int` | XP за день, `>= 0` |
| correctAnswers | `int` | Успешных ответов, `>= 0` |

## Value objects

### CardState
Состояние расписания SM-2 для одного слова. `easePermille` — ease, умноженный на 1000 (2500 = 2.5): целое масштабирование делает equality детерминированной. Фабрика `CardState.initial(dueAt)` даёт ease 2500 и нулевые счётчики.

| Поле | Тип | Назначение |
|---|---|---|
| easePermille | `int` | Ease-фактор × 1000, `>= 1300` |
| intervalDays | `int` | Интервал до следующего показа, `>= 0` |
| repetitions | `int` | Успешных повторений подряд, `>= 0` |
| lapses | `int` | Число провалов, `>= 0` |
| dueAt | `DateTime` | Когда слово снова доступно, всегда UTC |

Геттер `ease` возвращает `easePermille / 1000.0`.

### CefrLevel

`enum CefrLevel { a0, a1, a2, b1, b2, c1, c2 }` с `label` (`A0`…`C2`) и `description` (ADR-023). Порядок значений — шкала сложности, поэтому сравнение уровней идёт через `index`, а не через строку. `fromLabel` разбирает метку без учёта регистра и бросает `ArgumentError` на неизвестной. `A0` — Pre-A1, вне оригинального CEFR: слова до первого уровня.

В БД хранится метка в нижнем регистре (`a0`…`c2`, DDL-дефолт `a1`) — индексы enum привязаны к порядку в коде и для данных непригодны.

### StreakRule
Правила выдачи заморозок (ADR-015). `StreakRule.frozenEarnedFor(streakCount)`: 0 до 7 дней, 1 на 7, 2 на 30; `StreakRule.maxAvailable = 2`. Класс статический (`abstract final`), состояния не имеет: баланс выводится из длины серии и размера `frozenDates`.

### StreakInfo
Результат расчёта серии. Не хранится, вычисляется из логов.

| Поле | Тип | Назначение |
|---|---|---|
| count | `int` | Длина текущей серии в локальных днях, `>= 0`; замороженный день входит в счёт |
| lastActiveLocalDate | `LocalDate?` | Последний день с активностью, null если истории нет |
| frozenAvailable | `int` | Сколько заморозок можно потратить сейчас (заработано по вехам минус израсходовано), `0..2` |
| frozenDates | `Set<LocalDate>` | Даты, уже покрытые заморозкой |

### ExportPayload
Снимок полного состояния для бэкапа. Не `const`: списки и множество копируются в unmodifiable. Валидация (поддерживаемые версии `1..5`, `exportedAt.isUtc`) — в `ImportProgress`, не в конструкторе. `ExportPayload.currentSchemaVersion = 5`.

Версии снимка: v1 — базовая, v2 — `frozenDays`, v3 — `Word.category`, v4 — `Word.level` (ADR-023). Старший снимок читается с дефолтами: `frozenDays` пустой, `category` null, `level` A1.

| Поле | Тип | Назначение |
|---|---|---|
| schemaVersion | `int` | Версия схемы: 1–5 читаются, 6+ отклоняется |
| exportedAt | `DateTime` | Момент снимка, UTC |
| settings | `UserSettings` | Настройки на момент экспорта |
| words | `List<Word>` | Словарь; `category` с v3, `level` с v4 |
| progress | `List<WordProgress>` | Прогресс |
| logs | `List<ReviewLog>` | Журнал ответов |
| stats | `List<DailyStats>` | Дневная статистика |
| frozenDays | `Set<LocalDate>` | Замороженные дни серии (v2; в v1 пусто) |

Равенство — поэлементное по всем спискам и по `frozenDays` (порядок не важен). JSON: `frozenDays` — массив `daysSinceEpoch`; снимок v1 без поля читается как пустое множество, v2 без поля — `FormatException`.

## SRS

`SrsCalculator` — интерфейс алгоритма повторений. Реализация: `Sm2SrsCalculator` (Phase 1.1c).

- `CardState apply(CardState current, ReviewGrade grade, DateTime now)`
- Δ ease в permille: again −800, hard −140, good 0, easy +100; пол 1300.
- Интервалы: repetitions 1 → 1 день, 2 → 6 дней, ≥ 3 → `interval × EF` с округлением.
- `dueAt = now + interval` без выравнивания на полночь (улучшение Phase 3).
- Чистая функция: от системных часов не зависит.
- `now` — UTC; при нарушении бросается `ArgumentError` (runtime-проверка, не assert — release-safe).

## Serialization contract

`ExportPayloadCodec` (`lib/data/export_payload_codec.dart`) — единственное место JSON-сериализации схемы v1: компактный JSON, все моменты времени в UTC ISO-8601, enum'ы по `.name`, `DailyStats.date` — числом `daysSinceEpoch`. `decode` бросает `FormatException` на любое структурное несоответствие; экраны получают кодек через `payloadCodecProvider`, чтобы presentation не импортировал data.

`WordStatus` сериализуется как часть `WordProgress`, не `Word`: статус живёт только в прогрессе (ADR-004). Значение пишется по `.name`; переименование — breaking change, требует миграции в data-слое. То же для enum `ReviewGrade`: `.name` → `again` / `hard` / `good` / `easy`. Do NOT serialize enums by `.index`: index is not a stable key, он меняется при вставке значения в середину списка.

## Repository interfaces

Контракты объявлены в domain, реализуются в data на Drift. Ни один метод не принимает и не возвращает типы Drift, Flutter и виджетов.

### WordRepository
- `Future<Word?> getById(WordId id)`
- `Future<List<Word>> getByIds(Iterable<WordId> ids)`
- `Future<List<Word>> getAll()`
- `Future<List<Word>> search(String query)`
- `Future<void> upsert(Word word)`
- `Future<void> insertMany(Iterable<Word> words)` — атомарно, для seed
- `Future<void> delete(WordId id)`
- `Future<void> replaceAll(Iterable<Word> words)` — импорт/восстановление

### ProgressRepository
- `Future<WordProgress?> getByWordId(WordId wordId)`
- `Future<List<WordProgress>> getByStatus(WordStatus status)`
- `Future<List<WordProgress>> getAll()`
- `Future<List<WordProgress>> getDueBefore(DateTime utcInstant)`
- `Future<void> upsert(WordProgress progress)`
- `Future<void> replaceAll(Iterable<WordProgress> items)`

### SettingsRepository
- `Future<UserSettings> get()`
- `Future<void> save(UserSettings settings)`

### ReviewLogRepository
- `Future<void> append(ReviewLog log)` — единственная операция для учебного цикла
- `Future<List<ReviewLog>> getByWordId(WordId wordId)`
- `Future<List<ReviewLog>> getAll()`
- `Future<List<ReviewLog>> getByDateRange(DateTime fromUtc, DateTime toUtc)`
- `Future<void> replaceAll(Iterable<ReviewLog> logs)` — исключение из append-only, только импорт (ADR-005)

### StatsRepository
- `Future<DailyStats?> getForDate(LocalDate date)`
- `Future<List<DailyStats>> getRange(LocalDate from, LocalDate to)`
- `Future<List<DailyStats>> getAll()`
- `Future<LocalDate?> getLastActiveDate()`
- `Future<void> upsert(DailyStats stats)`
- `Future<void> replaceAll(Iterable<DailyStats> items)`

## Use cases

| Use case | Сигнатура | Поведение |
|---|---|---|
| GetTodayQueue | `GetTodayQueue({required WordRepository words, required ProgressRepository progress, required SettingsRepository settings, required DateTime Function() clock})` → `Future<TodayQueue>` | слова и прогресс сопоставляются по `wordId`: newWords — слова без прогресса или со статусом `newWord` **и уровнем не выше `settings.preferredLevel`** (ADR-023; порядок: `firstSeenAt` asc, затем слова без прогресса по `id`), due — прогресс с наступившим `dueAt` вне `newWord` (порядок: `dueAt` asc), **без фильтра по уровню** — начатое слово повторяется по SM-2; оба списка обрезаны `dailyNewLimit` / `dailyReviewLimit` |
| RecordReview | `RecordReview({required ProgressRepository progress, required ReviewLogRepository reviewLog, required StatsRepository stats, required WordRepository words, required SrsCalculator srs, required ReviewLogId Function() nextLogId, required DateTime Function() clock})` → `Future<CardState>` | проверяет существование слова; создаёт или обновляет прогресс, пишет ReviewLog, поднимает DailyStats. Статус: mastered при `reps ≥ 5 && intervalDays ≥ 21` (Anki-style mature); `lapses` не блокирует — история провалов не мешает mastered. Иначе learning: после любого ответа слово уже видели, `newWord` только до первого ответа |
| ExportProgress | `ExportProgress({settings, progress, reviewLog, stats, words, frozen, clock})` → `Future<ExportPayload>` | снимок всей базы через `getAll`; не зависит от перечисления статусов и диапазонов дат; `schemaVersion = ExportPayload.currentSchemaVersion` (5, есть `frozenDays` + `category` + `level` + `preferredLevel`) |
| ImportProgress | `ImportProgress({words, progress, reviewLog, settings, stats, frozen})` → `Future<void>` | REPLACE через `replaceAll`; валидирует `schemaVersion in 1..ExportPayload.currentSchemaVersion` (сейчас 1..5) и `exportedAt.isUtc`; порядок settings → words → progress → logs → stats → frozen; снимки старших версий читаются с дефолтами (`frozenDays` пустой, `category` null, `level` A1, `preferredLevel` A1); атомарность per-repo |
| ComputeStreak | `ComputeStreak({required StatsRepository stats, required FrozenDaysRepository frozen, required DateTime Function() clock})` → `Future<StreakInfo>` | 3 запроса: `getLastActiveDate` + `getRange` + `FrozenDays.getAll`; локальная дата `clock().toLocal()`, окно `_lookbackDays = 3650`; замороженный день продолжает серию и входит в счёт; `frozenAvailable` — `StreakRule.frozenEarnedFor(count)` минус израсходованные, клампится в `[0, 2]` |
| MarkMissedDay | `MarkMissedDay({required FrozenDaysRepository frozen})` → `Future<void>` | ставит заморозку на дату с причиной `missedDay`; вызывается из `bootstrapApp` для вчерашнего пропуска (ADR-015) |
| ResetProgress | `ResetProgress({required ProgressRepository progress, required ReviewLogRepository reviewLog, required StatsRepository stats, required FrozenDaysRepository frozen})` → `Future<void>` | очищает прогресс → логи → статистику → заморозки; слова и настройки сохраняются (ADR-013, BL-51) |
| GetWordHint | `GetWordHint({required WordHintRepository hints, required HintGenerator generator, required DateTime Function() clock})` → `Future<String>` | кэш `word_hints` → AI → кэш; запись валидна только при совпадении `term` (инвалидация при редактировании слова); ошибка генератора не кэшируется (ADR-019) |
| GetAnalytics | `GetAnalytics({required WordRepository words, required ProgressRepository progress, required StatsRepository stats, required DateTime Function() clock})` → `Future<Analytics>` | только чтение: счётчики по статусам (слово без прогресса — новое), топ-5 по `lapses`, `getRange` за 7 дней, прогноз `mastered / дни` → `LocalDate?` (null без `mastered`) (ADR-021) |

Поддерживающие типы `QueueItem`, `RecordReviewResult`, `ExportPayload`, `ImportResult`, `WordId`, `ReviewLogId`, `ReviewGrade`, `LocalDate` определяются в 1.1a вместе с сущностями.

## Data

Схема v15 — шестнадцать таблиц Drift (`lib/data/db/tables.dart`). Все временные метки — целые миллисекунды UTC. `onCreate` создаёт все таблицы, `onUpgrade` докатывает недостающее: v1→v2 создаёт `frozen_days`, v2→v3 добавляет `words.category` (`m.addColumn`), v3→v4 создаёт `word_hints`, v4→v5 добавляет `user_settings.has_seen_onboarding`, v5→v6 добавляет `words.level` и `user_settings.preferred_level` (ADR-023), v6→v7 создаёт `cloze_tasks` (ADR-025), v7→v8 создаёт `daily_challenges` (ADR-030), v8→v9 создаёт `challenge_streaks` (ADR-032), v9→v10 создаёт `user_categories` и вставляет 4 базовые категории (ADR-034), v10→v11 создаёт `achievements` (ADR-035), v11→v12 создаёт `typing_records` (ADR-037), v12→v13 создаёт `phrases` (ADR-038), v13→v14 создаёт `stories` (ADR-039), v14→v15 создаёт `chat_messages` (ADR-041) — существующие таблицы и данные не пересоздаются.

| Таблица | Data-класс | Первичный ключ | Индексы |
|---|---|---|---|
| `words` | `Word` | `id` (из `WordId.value`, без autoIncrement); `category` nullable (v3); `level` текст `a0`…`c2`, default `a1` (v6, ADR-023) | `idx_words_term` |
| `word_progresses` | `WordProgressRow` | `wordId` → `words.id` ON DELETE CASCADE | `idx_word_progress_due`, `idx_word_progress_status` |
| `review_logs` | `ReviewLogRow` | `id` | `idx_review_logs_word`, `idx_review_logs_reviewed` |
| `user_settings` | `UserSettingsRow` | `id` + `CHECK (id = 1)` | нет |
| `daily_stats` | `DailyStatsRow` | `dateEpochDays` (`LocalDate.daysSinceEpoch`) | нет |
| `frozen_days` | `FrozenDayRow` | `dateEpochDays` (`LocalDate.daysSinceEpoch`), схема v2 | нет |
| `word_hints` | `WordHintRow` | `wordId` → `words.id` ON DELETE CASCADE, схема v4 | нет |
| `cloze_tasks` | `ClozeTaskRow` | `wordId` (PK, FK → `words.id`) ON DELETE CASCADE; колонки `sentence`, `answer`, `createdAtUtc`; схема v7 | нет |
| `daily_challenges` | `DailyChallengeRow` | `dateEpochDays` (`LocalDate.daysSinceEpoch`); колонки `goalType` (имя `DailyChallengeType`), `goalValue`, `progress`, `completedAtUtc`, `claimedAtUtc`, `xpReward`; схема v8 | нет |
| `challenge_streaks` | `ChallengeStreakRow` | `id` + `CHECK (id = 1)`; колонки `currentStreak`, `bestStreak`, `lastCompletedDateEpochDays`, `updatedAtUtc`; схема v9 | нет |
| `user_categories` | `UserCategoryRow` | `id` (autoIncrement), `name` (`UNIQUE`); колонки `colorHex`, `createdAtUtc`; схема v10 | unique(`name`) |
| `achievements` | `AchievementRow` | `id` (строковый `AchievementType.key`); колонки `unlockedAtUtc` (nullable), `progress`, `lastUpdatedAtUtc`; схема v11 | нет |
| `typing_records` | `TypingRecordRow` | `id` (autoIncrement); колонки `wordsCount`, `correctCount`, `durationSeconds`, `wpm`, `accuracyPercent`, `score`, `createdAtUtc`; схема v12 | нет |
| `phrases` | `PhraseRow` | `id` (autoIncrement); колонки `phrase`, `translation`, `category`, `level`, `createdAtUtc`; схема v13 | нет |
| `stories` | `StoryRow` | `id` (autoIncrement); колонки `title`, `text` (getter `content`), `translation`, `level`, `createdAtUtc`; схема v14 | нет |
| `chat_messages` | `ChatMessageRow` | `id` (autoIncrement); колонки `role` ('user'/'assistant'), `content`, `createdAtUtc`; схема v15 | `idx_chat_messages_created` |

**Mapping domain↔data.** `CardState` раскладывается на колонки `easePermille`, `intervalDays`, `repetitions`, `lapses`, `dueAtUtc` в двух местах: в `word_progresses` (текущее состояние) и в `review_logs` (два снимка — `prev*` и `new*`). Обратное свёртывание — задача маппера 2a.2.

**`review_logs.wordId` без внешнего ключа.** Логи должны пережить удаление слова: иначе история обучения исчезает вместе со словарём. Каскад есть только у прогресса.

**`user_settings` — синглтон** через `CHECK (id = 1)`; вторая строка отвергается на уровне SQLite. Плюс `CHECK (tts_speed BETWEEN 0.1 AND 1.0)` — `ttsSpeed` хранится как `real`, не permille: диапазон узкий, сравнение всё равно идёт в домене через double.

**Версия схемы: 15.** `MigrationStrategy`: `onCreate = createAll`, `beforeOpen` включает `PRAGMA foreign_keys = ON` (SQLite не проверяет FK иначе — без этого каскад молча не работает). Миграции начинаются с v2.

Инициализация из `assets/seed/` — 2a.2 (BL-29).

**Реализации репозиториев** — `lib/data/repositories/*.dart`: `DriftWordRepository`, `DriftProgressRepository`, `DriftReviewLogRepository`, `DriftSettingsRepository`, `DriftStatsRepository`. Каждая — `final class` поверх `AppDatabase` и мапперов. `insertMany` и `replaceAll` идут в одной транзакции; `getDueBefore` и `getByDateRange` бросают `ArgumentError` на не-UTC. `WordRepository.nextId()` — `SELECT COALESCE(MAX(id), 0) + 1` без чтения таблицы в память; удалённые id не переиспользуются, атомарность при параллельных вставках — BL-39.

**`WordRepository.search` фильтрует в Dart, не в SQL.** `LIKE` в SQLite регистронезависим только для ASCII, а переводы кириллические — поиск «книга» не находил «Книга». Для словаря в сотни слов линейный проход дешевле FTS-индекса; при росте объёма — BL-32.

**`JsonSeedLoader` работает через `WordRepository`**, а не через `AppDatabase`: `count() > 0` → выход, иначе `insertMany` одной транзакцией. Падение откатывает весь батч, повторный запуск пробует снова.

## DI

Providers — `lib/core/di/providers.dart`, Riverpod 3.x без codegen (`riverpod_annotation` — 2a.3, BL-26).

| Группа | Провайдеры |
|---|---|
| Инфраструктура | `appDatabaseProvider` (override в `main`), `clockProvider`, `assetBundleProvider` (override в тестах), `nextReviewLogIdProvider` (override в `main`), `crashReporterProvider` (override в `main`, ADR-016), `notificationServiceProvider` (override в `main`, ADR-017), `srsCalculatorProvider` |
| Репозитории | `wordRepositoryProvider`, `progressRepositoryProvider`, `reviewLogRepositoryProvider`, `settingsRepositoryProvider`, `statsRepositoryProvider` |
| Use cases | `getTodayQueueUseCaseProvider`, `recordReviewProvider`, `computeStreakUseCaseProvider`, `exportProgressProvider`, `importProgressProvider` |
| Async-данные экрана | `getTodayQueueProvider`, `computeStreakProvider`, `dailyGoalProvider` |
| Сброс и бэкап | `resetProgressProvider` (ADR-013), `exportProgressProvider`, `importProgressProvider`, `payloadCodecProvider` (ADR-014) |
| Облако (ADR-022) | `isCloudConfiguredProvider`, `supabaseClientProvider` (`SupabaseClient?`), `cloudAuthServiceProvider`, `cloudEmailProvider` (`StreamProvider<String?>`), `cloudSyncServiceProvider` |
| Прочее | `seedLoaderProvider` |

Async-данные — `FutureProvider`: состоянием владеет провайдер, поэтому `ref.invalidate` действительно запускает пересчёт. Использовать `AsyncValue.when` в UI, не `FutureBuilder` с future из `build` — иначе кэш живёт до следующего rebuild и главный экран показывает прогресс до урока (BL-41, исправлено в 4b.1). UseCase-провайдеры оставлены отдельно: тесты подменяют реализацию через `overrideWithValue`, не трогая async-состояние. `LessonScreen` инвалидирует все три после сессии и при закрытии.

`appDatabaseProvider`, `nextReviewLogIdProvider`, `crashReporterProvider` и `notificationServiceProvider` намеренно бросают `UnimplementedError`: их переопределяют `main` и тесты, чтобы не тащить файловую базу, глобальный счётчик и нативный SDK. `assetBundleProvider` даёт `rootBundle` по умолчанию и подменяется в тестах.

Bootstrap (`bootstrapApp` в `main.dart`): `AppDatabase()` → `seedLoader.loadIfEmpty()` в отдельном `ProviderContainer` → `SELECT MAX(id)` → `NextReviewLogIdGenerator(max + 1)` → `runApp` с overrides (ADR-009). **Seed обёрнут в try/catch: падение загрузчика логируется, но не блокирует запуск — приложение стартует с пустой БД, seed повторится на следующем запуске (`count() == 0`).**

Сброс `nextReviewLogIdProvider` после `ImportProgress` не реализован: импорт пока не вызывается из UI, пересчёт `max(id)` — Phase 5 (BL-36).

## Presentation

- `lib/presentation/theme.dart` — Material 3, seed `Colors.teal`, пастельный фон.
- `lib/presentation/router.dart` — `routerProvider` (GoRouter): `/`, `/lesson`, `/dictionary`, `/profile`.
- `lib/presentation/screens/` — `HomeScreen` (серия, дневная цель, запуск урока, `NavigationBar`), `LessonScreen` (сессия), `DictionaryScreen` (словарь), `ProfileScreen` (настройки и скорость TTS). Плюс `ErrorHunterScreen` (`/error-hunter`) — мини-игра «Охота на ошибки» (Phase 8). В `ProfileScreen` — `AnalyticsSection` (плитки, 7-дневный график, трудные слова, прогноз; ADR-021).
- `lib/presentation/widgets/streak_card.dart` — серия дней из `StreakInfo`: крупная цифра, остаток до вехи 7, поздравления на 7/30/100/365, остаток заморозок (`frozenAvailable`) и бейдж «Freeze использован», если заморозка израсходована за последние 7 дней (ADR-015). Дату `today` передаёт экран — виджет не читает часы сам.
- `lib/presentation/widgets/cefr_badge.dart` — `CefrBadge` + `cefrLevelColor`: бейдж уровня на карточке урока (правый верхний угол) и в строке словаря. Цвет фиксирован по уровню (`teal` → `red`), а не берётся из темы: он кодирует сам уровень (ADR-023).
- `DictionaryScreen` — два независимых фильтра (категория и уровень) плюс вкладки статуса; складываются по AND. Уровень не влияет на очередь дня.
- `lib/presentation/widgets/daily_goal_card.dart` — «сделано / план» из `DailyStats.totalAnswers` и суммы `dailyNewLimit + dailyReviewLimit`; полоска обрезана на 100%, счётчик показывает факт (перебор виден как «7 / 5»).
- `HomeScreen` не считает сам: серию берёт у `ComputeStreak`, очередь у `GetTodayQueue`, план — сумма лимитов `UserSettings`. Кнопка старта выключена при пустой очереди; ошибка очереди показывает «Повторить» и пересоздаёт репозитории через `ref.invalidate` (у `ConsumerWidget` нет `setState`).
- `lib/presentation/widgets/` — `WordCard` (термин + транскрипция, reveal перевода и примера через `AnimatedSwitcher`), `SessionSummary` (итоги + «Готово»).
- `lib/presentation/screens/dictionary_screen.dart` — словарь: поиск через `WordRepository.search`, вкладки `Все`/`Изучаю`/`Выучено`, добавление слова, состояния loading/empty/error.
- `lib/presentation/widgets/word_list_item.dart` — строка словаря: термин, перевод, транскрипция, чип статуса (`новое`/`изучаю`/`выучено`).
- `lib/presentation/widgets/add_word_dialog.dart` — форма добавления: term/translation обязательны, дубликат по терму требует подтверждения, id = `max(id) + 1` (временное решение).
- `lib/presentation/widgets/export_dialog.dart` — JSON схемы v1 (read-only, selectable) и кнопка копирования в буфер (ADR-014).
- `lib/presentation/widgets/import_dialog.dart` — вставка JSON, проверка разбора и версии схемы, подтверждение, затем `ImportProgress` (REPLACE).
- `ProfileScreen` — секции: дневные лимиты (слайдеры 0..50/0..200), озвучка, резервная копия, опасная зона (сброс прогресса за подтверждением), напоминания (disabled, Phase 5).
- `LessonScreen` обёрнут в `PopScope`: пока ответов нет, системный back закрывает экран сразу и инвалидирует кэш; если сессия начата — диалог «Завершить сессию?» (BL-43), после подтверждения кэш инвалидируется и экран закрывается.
- `lib/core/text/plural.dart` — `pluralize(n, one/few/many)`; единственное место правил русского склонения (используется в `StreakCard` и кнопке старта урока).

`DictionaryEntry` (`lib/domain/value_objects/`) — пара «слово + статус»; `status == null` означает отсутствие прогресса, такие слова видны только во вкладке «Все».

`LessonScreen` — `ConsumerStatefulWidget`: очередь грузится один раз (`ref.read(getTodayQueueProvider)`), `FutureBuilder` даёт три состояния (загрузка, ошибка, пустая очередь). Оценка — `Dismissible` (вправо `good`, влево `again`) или кнопки; каждая запись идёт через `recordReviewProvider`, после последней карточки — `SessionSummary`. Undo доступен до итогов и вызывает `undoLastReviewProvider` (ADR-010).

XP и признак «верно» считаются в домене: `XpRules` (hard 5, good 10, easy 15, again 0) и `RecordReview`, возвращающий `ReviewOutcome` (ADR-011). Экран только суммирует `outcome.xpGained`.

## Core services

- `lib/core/tts/tts_service.dart` — `TtsService` (интерфейс) + `SttsTtsService` (обёртка над `stts`, ADR-018). Голос — BCP-47 (`en-US`/`en-GB`), скорость в настройках 0.1..1.0 пересчитывается ×2 в rate платформы 0.1..10.0; значения берутся из `UserSettings`.
- `lib/core/notifications/notification_service.dart` — `NotificationService` (`requestPermission`, `scheduleDailyReminder`, `cancelAll`), `FlutterNotificationService` (плагин `flutter_local_notifications`) и `NoOpNotificationService` (fallback, если инициализация не удалась).
- Напоминание: `zonedSchedule` с `DateTimeComponents.time` (ежедневно) и `AndroidScheduleMode.inexactAllowWhileIdle`; `SCHEDULE_EXACT_ALARM` не запрашивается (ADR-017). Таймзона — `timezone` + `flutter_timezone`; `initializeTimeZones()` и `setLocalLocation` выполняются в `bootstrapApp`, падение даёт NoOp и warning в лог.
- Android: `compileSdk 36` литералом, desugaring `desugar_jdk_libs 2.1.4`, `multiDexEnabled`; манифест — `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver` и `ScheduledNotificationBootReceiver` (`exported="false"`).
- `lib/domain/services/hint_generator.dart` — `HintGenerator` (интерфейс) + `AiClient` (data, реализация через прокси): domain не импортирует `package:http` (ADR-019).
- `lib/domain/services/error_task_generator.dart` — `ErrorTaskGenerator` (интерфейс, Phase 8) + `AiClient.generateErrorTask` (прокси `type: error_hunter`, таймаут 15 с). Задание — `ErrorHunterTask` (VO с `fromJson`: `sentence`, `wrongWord`, `correctWord`, `options`). `correctWord` читается из ответа, если прокси его присылает; иначе выводится как первый вариант ≠ `wrongWord` (текущий контракт прокси, BL-59) и обязан присутствовать в `options`.
- `lib/data/repositories/drift_word_hint_repository.dart` — кэш подсказок `word_hints` (schema v4), время создания приходит из домена.
- `lib/domain/services/cloud_sync_service.dart` — `CloudSyncService` (`push`/`pull`/`sync`), `SyncReport`, `CloudSyncException` и заглушка `UnavailableCloudSyncService` (ADR-022). Реализация — `lib/data/sync/supabase_cloud_sync_service.dart`: слияние по `updatedAtUtc = lastReviewedAt ?? firstSeenAt`, строка с равной меткой не перезаписывается.
- `lib/domain/services/cloud_auth_service.dart` — `CloudAuthService` (`isAvailable`, `email`, `authChanges`, `signInWithMagicLink`, `signOut`); Supabase-реализация в `lib/data/sync/supabase_cloud_auth_service.dart`, magic link возвращается по схеме `io.supabase.englishedu://login-callback/` из манифеста.
- `lib/data/sync/remote_progress_row.dart` — DTO строки `user_progress` + интерфейс `RemoteProgressStore` (`fetchAll`/`upsertAll`). Транспорт отделён от Supabase, чтобы слияние тестировалось без сети.
- `lib/core/logger.dart` — `Logger`/`DebugLogger`.

Android: в `AndroidManifest.xml` добавлен `<queries>` с `android.intent.action.TTS_SERVICE`; других изменений нет.

Логирование — через `Logger` (`lib/core/logger.dart`); `debugPrint` допустим только внутри `DebugLogger`. Bootstrap (`main.dart`) логирует падение seed как warning, а ошибку чтения `MAX(id)` — как error, продолжая с генератором от 1.

**DailyStats и ReviewLogs — независимые источники.** Удаление слова не откатывает статистику. `ComputeStreak` читает `DailyStats`, а не логи. Это задумано: пользователь отвечал — факт остаётся, даже если слово удалили.

**Два уровня валидации.** `CHECK` в БД — last line of defense (ручные правки базы, seed, будущие миграции). `ArgumentError`/assert в domain — early detection, ошибка падает рядом с источником. Оба уровня сохраняются сознательно, дублирование оправдано разной ценой ошибки.

**`ttsSpeed` как `real`.** UI-слайдер с шагом 0.05 даёт точные double, поэтому permille не нужен. Если в 2a.3 увидим drift equality на double — переделать на `int ttsSpeedPermille` (BL-30).

## Observability

- `lib/core/crash_reporter.dart` — контракт `CrashReporter` (`captureException`, `setContext`) и две реализации: `SentryCrashReporter` (отправка в Sentry) и `NoOpCrashReporter` (ничего не делает). Presentation зависит от контракта, а не от SDK.
- `crashReporterProvider` по умолчанию бросает `UnimplementedError`: выбор между Sentry и заглушкой делает `main`, иначе сбой терялся бы молча.
- DSN — только `--dart-define=SENTRY_DSN=...`. Пустая строка → `NoOpCrashReporter`. Параметры: `sampleRate` 1.0 debug / 0.2 release, `tracesSampleRate: 0`, `sendDefaultPii: false`, `attachStacktrace: true` (ADR-016).
- `bootstrapApp` принимает `sentryDsn` и необязательный `sentryInit`: тесты подменяют инициализацию заглушкой, нативный SDK в `flutter test` не поднимается. Сбой `sentryInit` не блокирует старт — приложение продолжает работу с `NoOpCrashReporter`.
- Точки отправки: bootstrap (`bootstrap_seed`, `bootstrap_review_log_id`), `LessonScreen._grade` (`record_review`), `ImportDialog._submit` (`import`). Сбой сначала попадает в `Logger`, затем в `CrashReporter`; сообщение в UI не меняется.
- iOS: `sentry_flutter` 10.x использует SPM (CocoaPods удалён), `Podfile` не создаётся. Android: `minSdk 26` в `android/app/build.gradle.kts`; `compileSdk`/`targetSdk`/`ndkVersion` наследуются от Flutter.
- IP-адрес отключается в проекте Sentry (Project Settings → Security & Privacy) — это серверная настройка, клиент на неё не влияет.

## File layout

Текущее дерево (Phase 23):

- `lib/main.dart` — точка входа: `bootstrapApp` (crash reporting → seed → покрытие пропущенного дня → настройки → напоминания), `ProviderScope`, `MaterialApp.router`
- `lib/core/` — `logger.dart`, `crash_reporter.dart` (`SentryCrashReporter` / `NoOpCrashReporter`, ADR-016), `tts/`, `notifications/`, `text/plural.dart`
- `lib/core/di/providers.dart` — Riverpod-провайдеры (63), без codegen (BL-26)
- `lib/domain/entities/` — 8 сущностей: `word`, `word_progress`, `review_log`, `user_settings`, `daily_stats`, `phrase`, `story`, `chat_message`
- `lib/domain/value_objects/` — 32 VO: `card_state`, `local_date`, `cefr_level`, `streak_info`, `streak_rule`, `today_queue`, `export_payload`, `word_hint`, `cloze_task`, `scramble_puzzle`, `error_hunter_task`, `analytics`, `daily_goal`, `dictionary_entry`, `daily_challenge`, `daily_challenge_type`, `challenge_streak`, `smart_review_item`, `review_grade`, `review_outcome`, `review_log_id`, `word_id`, `word_status`, `xp_rules`, `user_category`, `achievement`, `achievement_type`, `memory_card`, `memory_game`, `typing_record`, `typing_session`, `chat_role`
- `lib/domain/repositories/` — 16 контрактов репозиториев
- `lib/domain/services/` — 7 контрактов: `hint_generator`, `cloze_generator`, `error_task_generator`, `chat_generator`, `error_explainer`, `cloud_auth_service`, `cloud_sync_service`
- `lib/domain/srs/` — `srs_calculator.dart`, `sm2_srs_calculator.dart`
- `lib/domain/usecases/` — 30 use case
- `lib/data/db/` — Drift: 16 таблиц (`tables.dart`), `AppDatabase`, миграции v1→v15, `app_database.g.dart` коммитится (ADR-008)
- `lib/data/mappers/` — 6 мапперов domain↔data
- `lib/data/repositories/` — 16 Drift-реализаций контрактов
- `lib/data/ai/ai_client.dart` — клиент прокси DeepSeek (ADR-019)
- `lib/data/sync/` — Supabase: `CloudAuthService`, `CloudSyncService`, `RemoteProgressStore` (ADR-022)
- `lib/data/seed_loader.dart`, `lib/data/export_payload_codec.dart` — seed и JSON-снимок
- `lib/presentation/screens/` — 17 экранов; `lib/presentation/widgets/` — 16 виджетов
- `lib/presentation/router.dart` — GoRouter, 19 маршрутов + гейт онбординга; `theme.dart` — Material 3 + Inter (офлайн)
- `test/` — 118 файлов тестов, зеркалят структуру `lib/`; `test/integration/` — сквозные сценарии и performance baseline
- `tools/` — 8 скриптов + 2 библиотеки: `generate_seed.dart`, `generate_phrases.dart`, `generate_stories.dart`, `merge_seeds.dart`, `merge_phrases.dart`, `merge_stories.dart`, `validate_seed.dart`, `review_seed.dart` + `validate_seed_lib.dart`, `review_seed_lib.dart`; `manual_review_overrides.json` — данные ручного ревью переводов
- `assets/seed/` — `words_v2.json` (2071 слово), `phrases_v1.json` (209 фраз), `stories_v1.json` (34 рассказа); `words_v1.json` и `words_<level>.json` — входные данные merge, в APK не попадают

Правила: один публичный тип на файл, имена файлов в snake_case, импорт через полный путь пакета.

## Verification

- `flutter analyze` — ноль issues, ноль `// ignore` (с Phase 2a; в Phase 1 был `dart analyze`).
- `flutter test` — зелёный (850 тестов: 627 `test()` + 223 `testWidgets()`, 118 файлов).
- Границы слоя: в `lib/domain/` нет импортов Flutter, Drift и пакетов слоя data. Проверяется линтером и CI.
- Покрытие domain ≥ 80% — с момента появления реализаций.
- `flutter analyze` и `flutter test` — с Phase 2a (Flutter bootstrap, ADR-006); в Phase 1 домен проверялся через `dart analyze` / `dart test`. `bash scripts/ci.sh` — локальная проверка (format + analyze + test).

## Non-goals

- Cloud sync: Supabase (ADR-022). Opt-in, локальная БД — источник истины. Синхронизируется только `WordProgress`.
- Multi-language — только пара en→ru, другие языки вне scope.
- Web / desktop — только мобильные платформы.
- AI-функции — Phase 8, post-launch, только через прокси.

## История версий схемы

Источник истины — `lib/data/db/app_database.dart` (`schemaVersion` + `onUpgrade`).

| Версия | Что добавляет миграция | Решение |
|---|---|---|
| v1 | Базовая схема: `words`, `word_progresses`, `review_logs`, `user_settings`, `daily_stats` | ADR-002 |
| v2 | `frozen_days` | ADR-015 |
| v3 | `words.category` | BL-57 |
| v4 | `word_hints` | ADR-019 |
| v5 | `user_settings.has_seen_onboarding` | BL-61 |
| v6 | `words.level`, `user_settings.preferred_level` (CEFR) | ADR-023 |
| v7 | `cloze_tasks` | ADR-025 |
| v8 | `daily_challenges` | ADR-030 |
| v9 | `challenge_streaks` | ADR-032 |
| v10 | `user_categories` (+ 4 базовые категории) | ADR-034 |
| v11 | `achievements` | ADR-035 |
| v12 | `typing_records` | ADR-037 |
| v13 | `phrases` | ADR-038 |
| v14 | `stories` | ADR-039 |
| v15 | `chat_messages` | ADR-041 |
