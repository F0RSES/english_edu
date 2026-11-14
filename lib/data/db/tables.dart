import 'package:drift/drift.dart';

/// Словарная статья. `id` приходит из домена (`WordId.value`), поэтому
/// `autoIncrement` не используется.
@DataClassName('Word')
@TableIndex(name: 'idx_words_term', columns: {#term})
class Words extends Table {
  @override
  String get tableName => 'words';

  /// Первичный ключ из домена.
  IntColumn get id => integer()();

  /// Английский термин в нижнем регистре.
  TextColumn get term => text()();

  /// Перевод на русский.
  TextColumn get translation => text()();

  /// IPA-транскрипция, если есть.
  TextColumn get transcription => text().nullable()();

  /// Часть речи, если известна.
  TextColumn get partOfSpeech => text().nullable()();

  /// Пример употребления.
  TextColumn get exampleSentence => text().nullable()();

  /// Тематическая категория слова; null — без категории (schema v3).
  ///
  /// Список категорий фиксирован в UI; пользовательские категории — BL-56.
  TextColumn get category => text().nullable()();

  /// Уровень по CEFR меткой: `a0`…`c2` (schema v6, ADR-023).
  ///
  /// Хранится как текст, а не как индекс enum: порядок значений в коде может
  /// измениться, а миграция чужого файла с числом стала бы неоднозначной.
  TextColumn get level => text().withDefault(const Constant('a1'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Кэш AI-подсказок (ADR-019): одна запись на слово.
///
/// `term` хранится рядом с подсказкой — по нему кэш инвалидируется, если слово
/// отредактировали. Удаление слова удаляет и подсказку.
@DataClassName('WordHintRow')
class WordHints extends Table {
  @override
  String get tableName => 'word_hints';

  /// Слово, к которому относится подсказка.
  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();

  /// Написание слова на момент генерации.
  TextColumn get term => text()();

  /// Текст подсказки.
  TextColumn get hintText => text()();

  /// Момент сохранения, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// Кэш заданий «Заполни пропуск» (ADR-025): одна запись на слово.
///
/// Удаление слова удаляет и задание: пропуск без слова бессмыслен.
@DataClassName('ClozeTaskRow')
class ClozeTasks extends Table {
  @override
  String get tableName => 'cloze_tasks';

  /// Слово, к которому относится задание.
  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();

  /// Предложение с пропуском `___`.
  TextColumn get sentence => text()();

  /// Слово-ответ.
  TextColumn get answer => text()();

  /// Варианты ответа, JSON-массив из 5 строк (schema v16, ADR-025).
  ///
  /// null — запись до v16: без вариантов задание неиграбельно, репозиторий
  /// инвалидирует такой кэш и задание перегенерируется через AI.
  TextColumn get options => text().nullable()();

  /// Момент генерации, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// Состояние изучения слова. Одна запись на слово, удаляется каскадом
/// вместе со словом.
@DataClassName('WordProgressRow')
@TableIndex(name: 'idx_word_progress_due', columns: {#dueAtUtc})
@TableIndex(name: 'idx_word_progress_status', columns: {#status})
class WordProgresses extends Table {
  @override
  String get tableName => 'word_progresses';

  /// Ссылка на слово; удаление слова удаляет прогресс.
  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();

  /// Ease-фактор SM-2, умноженный на 1000.
  IntColumn get easePermille => integer()();

  /// Текущий интервал в днях.
  IntColumn get intervalDays => integer()();

  /// Успешных повторений подряд.
  IntColumn get repetitions => integer()();

  /// Провалов.
  IntColumn get lapses => integer()();

  /// Момент следующего показа, миллисекунды UTC.
  IntColumn get dueAtUtc => integer()();

  /// Статус: `newWord` | `learning` | `mastered`.
  TextColumn get status => text()();

  /// Первое появление, миллисекунды UTC.
  IntColumn get firstSeenAtUtc => integer()();

  /// Последний ответ, миллисекунды UTC; null — не отвечали.
  IntColumn get lastReviewedAtUtc => integer().nullable()();

  @override
  Set<Column> get primaryKey => {wordId};
}

/// Журнал ответов. Append-only.
///
/// У `wordId` намеренно НЕТ внешнего ключа: лог должен пережить удаление
/// слова, иначе история обучения разрушается вместе со словарём.
@DataClassName('ReviewLogRow')
@TableIndex(name: 'idx_review_logs_word', columns: {#wordId})
@TableIndex(name: 'idx_review_logs_reviewed', columns: {#reviewedAtUtc})
class ReviewLogs extends Table {
  @override
  String get tableName => 'review_logs';

  /// Идентификатор записи журнала.
  IntColumn get id => integer()();

  /// Слово, к которому относится ответ. Без FK — см. dartdoc класса.
  IntColumn get wordId => integer()();

  /// Момент ответа, миллисекунды UTC.
  IntColumn get reviewedAtUtc => integer()();

  /// Оценка: `again` | `hard` | `good` | `easy`.
  TextColumn get grade => text()();

  /// Ease до ответа.
  IntColumn get prevEasePermille => integer()();

  /// Интервал до ответа.
  IntColumn get prevIntervalDays => integer()();

  /// Повторений до ответа.
  IntColumn get prevRepetitions => integer()();

  /// Провалов до ответа.
  IntColumn get prevLapses => integer()();

  /// Дедлайн до ответа, миллисекунды UTC.
  IntColumn get prevDueAtUtc => integer()();

  /// Ease после ответа.
  IntColumn get newEasePermille => integer()();

  /// Интервал после ответа.
  IntColumn get newIntervalDays => integer()();

  /// Повторений после ответа.
  IntColumn get newRepetitions => integer()();

  /// Провалов после ответа.
  IntColumn get newLapses => integer()();

  /// Дедлайн после ответа, миллисекунды UTC.
  IntColumn get newDueAtUtc => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Настройки пользователя. Строго одна строка: `CHECK (id = 1)`.
@DataClassName('UserSettingsRow')
class UserSettingsTable extends Table {
  @override
  String get tableName => 'user_settings';

  /// Всегда 1 — синглтон обеспечивается CHECK-констрейнтом.
  IntColumn get id => integer()();

  /// Лимит новых слов в день.
  IntColumn get dailyNewLimit => integer().withDefault(const Constant(10))();

  /// Лимит повторений в день.
  IntColumn get dailyReviewLimit => integer().withDefault(const Constant(50))();

  /// Включены ли напоминания.
  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Час напоминания, 0..23.
  IntColumn get reminderHour => integer().withDefault(const Constant(9))();

  /// Минута напоминания, 0..59.
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();

  /// Идентификатор голоса TTS.
  TextColumn get ttsVoice => text().withDefault(const Constant('en-US'))();

  /// Скорость речи 0.1..1.0. `real`, а не permille: диапазон узкий,
  /// сравнение в домене идёт через double.
  RealColumn get ttsSpeed => real().withDefault(const Constant(0.5))();

  /// Пройден ли онбординг; false у новых установок (BL-61).
  BoolColumn get hasSeenOnboarding =>
      boolean().withDefault(const Constant(false))();

  /// Уровень пользователя по CEFR меткой: `a0`…`c2` (schema v6, ADR-023).
  ///
  /// Фильтрует новые слова в очереди дня; уже начатые слова не фильтруются.
  TextColumn get preferredLevel => text().withDefault(const Constant('a1'))();

  /// Язык интерфейса: 'ru' | 'en' (schema v17, Phase 27b).
  TextColumn get language => text().withDefault(const Constant('ru'))();

  /// Момент последнего изменения, миллисекунды UTC.
  IntColumn get updatedAtUtc => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (id = 1)',
    // Имя колонки — SQL-ное (snake_case), не Dart-ное.
    'CHECK (tts_speed BETWEEN 0.1 AND 1.0)',
  ];
}

/// Дневные счётчики. Первичный ключ — `LocalDate.daysSinceEpoch`.
@DataClassName('DailyStatsRow')
class DailyStatsTable extends Table {
  @override
  String get tableName => 'daily_stats';

  /// День в локальной TZ как число дней от эпохи.
  IntColumn get dateEpochDays => integer()();

  /// Новых слов показано.
  IntColumn get newWordsStudied => integer().withDefault(const Constant(0))();

  /// Повторений завершено.
  IntColumn get reviewsCompleted => integer().withDefault(const Constant(0))();

  /// XP за день.
  IntColumn get xpGained => integer().withDefault(const Constant(0))();

  /// Успешных ответов.
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {dateEpochDays};
}

/// Заморозки на конкретные даты. Заполняется при пропуске.
///
/// Первичный ключ — день: на дату приходится не больше одной заморозки.
/// `reason` сейчас только `missedDay`; `manual` зарезервирован для ручного
/// добавления из debug-меню (Phase 5e, BL-50).
@DataClassName('FrozenDayRow')
class FrozenDays extends Table {
  @override
  String get tableName => 'frozen_days';

  /// День в локальной TZ как число дней от эпохи.
  IntColumn get dateEpochDays => integer()();

  /// Момент, когда заморозка была израсходована, миллисекунды UTC.
  IntColumn get consumedAtUtc => integer()();

  /// Причина: `missedDay` | `manual`.
  TextColumn get reason => text()();

  @override
  Set<Column> get primaryKey => {dateEpochDays};
}

/// Ежедневное задание (Phase 15b, ADR-030). Одна запись на локальный день.
///
/// Тип хранится именем значения enum (`review20`, `streak10`, `new5`,
/// `noMistakes`), а не индексом: порядок значений в коде может измениться, и
/// числовой снимок стал бы неоднозначным (та же причина, что у `words.level`).
@DataClassName('DailyChallengeRow')
class DailyChallenges extends Table {
  @override
  String get tableName => 'daily_challenges';

  /// День в локальной TZ как число дней от эпохи.
  IntColumn get dateEpochDays => integer()();

  /// Тип задания: имя значения `DailyChallengeType`.
  TextColumn get goalType => text()();

  /// Сколько единиц нужно набрать.
  IntColumn get goalValue => integer()();

  /// Текущий прогресс. Может уменьшаться: серийные задания сбрасываются.
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// Момент выполнения, миллисекунды UTC; null — ещё не выполнено.
  IntColumn get completedAtUtc => integer().nullable()();

  /// Момент получения награды, миллисекунды UTC; null — не забрана.
  IntColumn get claimedAtUtc => integer().nullable()();

  /// Сколько XP начисляется за награду.
  IntColumn get xpReward => integer()();

  @override
  Set<Column> get primaryKey => {dateEpochDays};
}

/// Серия дней с выполненным ежедневным заданием (Phase 15d, ADR-032).
///
/// Синглтон: серия одна на устройство, поэтому `CHECK (id = 1)` отвергает
/// вторую строку на уровне SQLite (как у `user_settings`).
@DataClassName('ChallengeStreakRow')
class ChallengeStreaks extends Table {
  @override
  String get tableName => 'challenge_streaks';

  /// Всегда 1 — синглтон обеспечивается CHECK-констрейнтом.
  IntColumn get id => integer()();

  /// Текущая серия дней подряд.
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();

  /// Лучшая серия за всё время; не уменьшается.
  IntColumn get bestStreak => integer().withDefault(const Constant(0))();

  /// День последнего выполненного задания; null — ещё ни одного.
  IntColumn get lastCompletedDateEpochDays => integer().nullable()();

  /// Момент последнего изменения, миллисекунды UTC.
  IntColumn get updatedAtUtc => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

/// Категории слов, включая созданные пользователем (Phase 16c, ADR-034).
///
/// Четыре базовые категории вставляются миграцией v10, поэтому удалять их
/// нельзя (проверка по `id <= 4`). `UNIQUE (name)` не даёт создать дубль,
/// который фильтр словаря не смог бы различить.
@DataClassName('UserCategoryRow')
class UserCategories extends Table {
  @override
  String get tableName => 'user_categories';

  /// Автоинкремент: id базовых категорий фиксированы миграцией (1..4).
  IntColumn get id => integer().autoIncrement()();

  /// Название категории; уникально, регистр не нормализуется в БД.
  TextColumn get name => text().unique()();

  /// Цвет для чипа в UI, например `#FF5722`; null — цвет по умолчанию.
  TextColumn get colorHex => text().nullable()();

  /// Момент создания, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();
}

/// Разблокированные достижения и прогресс по ним (Phase 18, ADR-035).
///
/// Ключ — строковый `AchievementType.key` (`streak_7`, `words_100`), а не
/// числовой id: достижения приходят из кода, и порядок enum не должен влиять
/// на данные (та же причина, что у `words.level`).
@DataClassName('AchievementRow')
class Achievements extends Table {
  @override
  String get tableName => 'achievements';

  /// Ключ достижения из `AchievementType.key`.
  TextColumn get id => text()();

  /// Момент разблокировки, миллисекунды UTC; null — ещё не открыто.
  IntColumn get unlockedAtUtc => integer().nullable()();

  /// Текущий прогресс по метрике достижения.
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// Момент последнего пересчёта, миллисекунды UTC.
  IntColumn get lastUpdatedAtUtc => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Рекорды игры «Typing Speed» (Phase 21a, ADR-037).
///
/// Строка — одна завершённая сессия. Хранить их выгоднее, чем один счётчик:
/// экран показывает топ-10 и лучший результат, а история не теряется.
@DataClassName('TypingRecordRow')
class TypingRecords extends Table {
  @override
  String get tableName => 'typing_records';

  /// Автоинкремент: записи только добавляются.
  IntColumn get id => integer().autoIncrement()();

  /// Сколько слов было в сессии.
  IntColumn get wordsCount => integer()();

  /// Сколько набрано верно.
  IntColumn get correctCount => integer()();

  /// Длительность сессии в секундах.
  IntColumn get durationSeconds => integer()();

  /// Слов в минуту.
  IntColumn get wpm => integer()();

  /// Точность в процентах, 0..100.
  IntColumn get accuracyPercent => integer()();

  /// Итоговые очки: WPM, взвешенный точностью.
  IntColumn get score => integer()();

  /// Момент завершения, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();
}

/// Фразы разговорника (Phase 22, ADR-038).
///
/// Отдельная таблица, а не `words`: у фразы нет SM-2, прогресса и статуса —
/// это справочник, а не учебная карточка.
@DataClassName('PhraseRow')
class Phrases extends Table {
  @override
  String get tableName => 'phrases';

  /// Автоинкремент: контент только добавляется.
  IntColumn get id => integer().autoIncrement()();

  /// Английская фраза.
  TextColumn get phrase => text()();

  /// Русский перевод.
  TextColumn get translation => text()();

  /// Тема: «Приветствия», «Аэропорт», «Идиомы».
  TextColumn get category => text()();

  /// Уровень CEFR меткой: a1…c2.
  TextColumn get level => text()();

  /// Момент загрузки, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();
}

/// Рассказы для Reading Mode (Phase 23, ADR-039).
///
/// Отдельная таблица, а не `words`: рассказ — связный текст для чтения,
/// у него нет SM-2-прогресса и статуса учебной карточки.
@DataClassName('StoryRow')
class Stories extends Table {
  @override
  String get tableName => 'stories';

  /// Автоинкремент: контент только добавляется.
  IntColumn get id => integer().autoIncrement()();

  /// Заголовок рассказа.
  TextColumn get title => text()();

  /// Английский текст.
  ///
  /// Getter не может называться `text`: Dart запрещает одноимённые getter и
  /// унаследованный метод `Table.text()`. SQL-имя колонки остаётся `text`
  /// через `.named()`.
  TextColumn get content => text().named('text')();

  /// Русский перевод.
  TextColumn get translation => text()();

  /// Уровень CEFR меткой: a1…c1.
  TextColumn get level => text()();

  /// Момент загрузки, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();
}

/// Сообщения чата с AI-помощником (Phase 25a, ADR-041).
///
/// История хранится только локально и не синхронизируется в облако:
/// содержимое переписки — приватные данные пользователя.
@DataClassName('ChatMessageRow')
@TableIndex(name: 'idx_chat_messages_created', columns: {#createdAtUtc})
class ChatMessages extends Table {
  @override
  String get tableName => 'chat_messages';

  /// Автоинкремент: сообщения только добавляются.
  IntColumn get id => integer().autoIncrement()();

  /// Роль отправителя: имя значения `ChatRole` ('user' | 'assistant').
  TextColumn get role => text()();

  /// Текст сообщения.
  TextColumn get content => text()();

  /// Момент создания, миллисекунды UTC.
  IntColumn get createdAtUtc => integer()();
}
