# Architecture

Карта контрактов доменного слоя. Здесь описаны типы и сигнатуры; реализации появятся в 1.1a–1.1c.
Dart-код в документе не приводится: сигнатуры даны псевдо-Dart в backticks.

## Слои

- **presentation** — экраны и виджеты, state через Riverpod. Зависит от domain.
- **domain** — сущности, value objects, контракты репозиториев, use cases. Pure Dart, без Flutter SDK.
- **data** — Drift-база и реализации репозиториев. Зависит от domain.

Правило: presentation → domain ← data. Domain не импортирует ни presentation, ни data, ни Flutter.

## Entities

### Word
Словарная статья: то, что показывается в карточке урока.

| Поле | Тип | Назначение |
|---|---|---|
| id | `WordId` | Стабильный идентификатор слова в seed |
| lemma | `String` | Слово в начальной форме, английский |
| translation | `String` | Перевод, русский |
| partOfSpeech | `String?` | Часть речи, если известна |
| example | `String?` | Пример употребления на английском |
| transcription | `String?` | IPA-транскрипция |
| audioAsset | `String?` | Путь к локальному аудио, если есть |
| tags | `List<String>` | Теги: тема, уровень |
| createdAtUtc | `DateTime` | Когда слово попало в базу, UTC |

### WordProgress
Текущее состояние изучения слова: одна запись на слово.

| Поле | Тип | Назначение |
|---|---|---|
| wordId | `WordId` | Ссылка на Word |
| card | `CardState` | Расписание повторений |
| totalReviews | `int` | Сколько раз слово оценено |
| firstSeenAtUtc | `DateTime` | Первое появление в уроке, UTC |
| lastReviewedAtUtc | `DateTime?` | Последняя оценка, UTC |
| isSuspended | `bool` | Исключено из очереди пользователем |

### ReviewLog
Неизменяемая запись о попытке. Источник правды для статистики и streak.

| Поле | Тип | Назначение |
|---|---|---|
| id | `ReviewLogId` | Идентификатор записи |
| wordId | `WordId` | Какое слово оценивали |
| reviewedAtUtc | `DateTime` | Момент ответа, UTC |
| grade | `ReviewGrade` | Оценка: again / hard / good / easy |
| previousIntervalDays | `int` | Интервал до ответа |
| nextIntervalDays | `int` | Интервал после ответа |
| nextEase | `double` | Ease после пересчёта |
| durationMs | `int` | Время ответа |
| sessionId | `String?` | Группа повторений в одной сессии |

### UserSettings
Пользовательские настройки: одна запись на устройство.

| Поле | Тип | Назначение |
|---|---|---|
| dailyGoal | `int` | Цель повторений в день |
| newWordsPerDay | `int` | Лимит новых слов в день |
| ttsEnabled | `bool` | Озвучивание включено |
| ttsVoiceId | `String?` | Выбранный голос |
| notificationsEnabled | `bool` | Локальные напоминания включены |
| reminderLocalTime | `String?` | Время напоминания в формате HH:mm, локальная TZ |
| timeZoneId | `String?` | IANA-идентификатор TZ, если зафиксирован явно |
| updatedAtUtc | `DateTime` | Последнее изменение, UTC |

### DailyStats
Агрегат по одному локальному дню. Вычисляется из ReviewLog, вручную не вводится.

| Поле | Тип | Назначение |
|---|---|---|
| localDate | `LocalDate` | День в локальной TZ пользователя |
| reviewsCount | `int` | Повторений за день |
| newWordsCount | `int` | Новых слов за день |
| xpEarned | `int` | XP за день |
| goalReached | `bool` | Дневная цель достигнута |

## Value objects

### CardState
Состояние расписания SM-2 для одного слова.

| Поле | Тип | Назначение |
|---|---|---|
| ease | `double` | Текущий ease-фактор |
| intervalDays | `int` | Интервал до следующего показа |
| repetitions | `int` | Успешных повторений подряд |
| lapses | `int` | Число провалов |
| dueAtUtc | `DateTime` | Когда слово снова доступно, UTC |

### StreakInfo
Результат расчёта серии. Не хранится, вычисляется из логов.

| Поле | Тип | Назначение |
|---|---|---|
| count | `int` | Длина текущей серии в локальных днях |
| lastActiveLocalDate | `LocalDate?` | Последний день с активностью |
| isActiveToday | `bool` | Активность уже была сегодня |

## Repository interfaces

Контракты объявлены в domain, реализуются в data на Drift. Ни один метод не принимает и не возвращает типы Drift, Flutter и виджетов.

### WordRepository
- `Future<Word?> getById(WordId id)`
- `Future<List<Word>> getByIds(List<WordId> ids)`
- `Future<List<Word>> getAll()`
- `Future<int> count()`
- `Future<void> upsertAll(List<Word> words)`

### ProgressRepository
- `Future<List<WordProgress>> getDue(DateTime nowUtc, {required int limit})`
- `Future<WordProgress?> getByWordId(WordId wordId)`
- `Future<void> saveAll(List<WordProgress> items)`
- `Future<void> appendReview(ReviewLog log)`
- `Future<List<ReviewLog>> getReviewsSince(DateTime sinceUtc)`
- `Future<int> countReviewsBetween(DateTime fromUtc, DateTime toUtc)`

### SettingsRepository
- `Future<UserSettings> read()`
- `Future<void> write(UserSettings settings)`
- `Stream<UserSettings> watch()`

## Use cases

| Use case | Вход | Выход |
|---|---|---|
| GetTodayQueue | `DateTime nowUtc`, `int limit` | `Future<List<QueueItem>>`: сначала due, затем новые |
| RecordReview | `WordId wordId`, `ReviewGrade grade`, `DateTime nowUtc`, `int durationMs` | `Future<RecordReviewResult>`: новый CardState и ReviewLog |
| ExportProgress | `DateTime nowUtc` | `Future<ExportPayload>`: schemaVersion и строки прогресса |
| ImportProgress | `ExportPayload payload` | `Future<ImportResult>`: added / updated / skipped / rejected |
| ComputeStreak | `List<LocalDate> activeDates`, `LocalDate todayLocal` | `StreakInfo` |

Поддерживающие типы `QueueItem`, `RecordReviewResult`, `ExportPayload`, `ImportResult`, `WordId`, `ReviewLogId`, `ReviewGrade`, `LocalDate` определяются в 1.1a вместе с сущностями.

## File layout

Планируемое дерево доменного слоя; файлы появятся в 1.1a–1.1c:

- `lib/domain/entities/` — `word.dart`, `word_progress.dart`, `review_log.dart`, `user_settings.dart`, `daily_stats.dart`
- `lib/domain/value_objects/` — `word_id.dart`, `review_log_id.dart`, `review_grade.dart`, `local_date.dart`, `card_state.dart`, `streak_info.dart`
- `lib/domain/repositories/` — `word_repository.dart`, `progress_repository.dart`, `settings_repository.dart`
- `lib/domain/use_cases/` — `get_today_queue.dart`, `record_review.dart`, `export_progress.dart`, `import_progress.dart`, `compute_streak.dart`
- `test/domain/` — тесты, зеркалящие структуру `lib/domain/`

Правила: один публичный тип на файл, имена файлов в snake_case, импорт через полный путь пакета.

## Verification

- `dart analyze` — ноль issues, ноль `// ignore`.
- `dart test test/domain/` — зелёный.
- Границы слоя: в `lib/domain/` нет импортов Flutter, Drift и пакетов слоя data. На 1.1 проверяется чтением импортов, с Phase 2a — линтером и CI.
- Покрытие domain ≥ 80% — цель с момента появления реализаций (1.1b+); на 1.1 контракты тестами не покрываются.
- `flutter analyze` и `flutter test` подключаются в Phase 2a вместе с Flutter SDK.

## Non-goals

- Cloud sync — прогресс живёт только на устройстве, сервера нет.
- Accounts / auth — регистрации и входа нет, приложение локальное.
- Multi-language — только пара en→ru, другие языки вне scope.
- Web / desktop — только мобильные платформы.
- AI-функции — Phase 8, post-launch, только через прокси.
