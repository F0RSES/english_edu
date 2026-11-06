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
