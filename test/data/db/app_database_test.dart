import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:test/test.dart';

const _nowMs = 1715774400000; // 2024-05-15T12:00:00Z

AppDatabase openDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> insertWord(AppDatabase db, int id, {String term = 'hello'}) => db
    .into(db.words)
    .insert(
      WordsCompanion.insert(id: Value(id), term: term, translation: 'привет'),
    );

Future<void> insertProgress(AppDatabase db, int wordId) => db
    .into(db.wordProgresses)
    .insert(
      WordProgressesCompanion.insert(
        wordId: Value(wordId),
        easePermille: 2500,
        intervalDays: 1,
        repetitions: 1,
        lapses: 0,
        dueAtUtc: _nowMs,
        status: 'learning',
        firstSeenAtUtc: _nowMs,
      ),
    );

Future<void> insertLog(AppDatabase db, int wordId) => db
    .into(db.reviewLogs)
    .insert(
      ReviewLogsCompanion.insert(
        id: const Value(1),
        wordId: wordId,
        reviewedAtUtc: _nowMs,
        grade: 'good',
        prevEasePermille: 2500,
        prevIntervalDays: 1,
        prevRepetitions: 0,
        prevLapses: 0,
        prevDueAtUtc: _nowMs,
        newEasePermille: 2500,
        newIntervalDays: 6,
        newRepetitions: 1,
        newLapses: 0,
        newDueAtUtc: _nowMs,
      ),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = openDb());
  tearDown(() => db.close());

  test('migration v3 to v4 creates the word_hints table', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v4');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v3 = текущая схема без кэша подсказок.
    final v3 = AppDatabase.forTesting(NativeDatabase(file));
    await v3
        .into(v3.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'book',
            translation: 'книга',
            category: const Value('Быт'),
          ),
        );
    await v3.customStatement('DROP TABLE word_hints');
    await v3.customStatement(
      'ALTER TABLE user_settings DROP COLUMN has_seen_onboarding',
    );
    await v3.customStatement('ALTER TABLE words DROP COLUMN level');
    await v3.customStatement(
      'ALTER TABLE user_settings DROP COLUMN preferred_level',
    );
    await v3.customStatement('DROP TABLE cloze_tasks');
    await v3.customStatement('PRAGMA user_version = 3');
    await v3.close();

    final v4 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v4.close);

    // Таблица создана миграцией: запрос не падает и возвращает пусто.
    expect(await v4.select(v4.wordHints).get(), isEmpty);
    // Данные v3 пережили миграцию, включая category из v3.
    final row = (await v4.select(v4.words).get()).single;
    expect(row.term, 'book');
    expect(row.category, 'Быт');
  });

  test('migration v4 to v5 adds the onboarding flag', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v5');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v4 = текущая схема без флага онбординга.
    final v4 = AppDatabase.forTesting(NativeDatabase(file));
    await v4
        .into(v4.userSettingsTable)
        .insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            updatedAtUtc: _nowMs,
          ),
        );
    await v4.customStatement(
      'ALTER TABLE user_settings DROP COLUMN has_seen_onboarding',
    );
    await v4.customStatement('ALTER TABLE words DROP COLUMN level');
    await v4.customStatement(
      'ALTER TABLE user_settings DROP COLUMN preferred_level',
    );
    await v4.customStatement('DROP TABLE cloze_tasks');
    await v4.customStatement('PRAGMA user_version = 4');
    await v4.close();

    final v5 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v5.close);

    // Колонка появилась миграцией; старая строка получила дефолт false.
    final row = (await v5.select(v5.userSettingsTable).get()).single;
    expect(row.hasSeenOnboarding, isFalse);
    expect(row.updatedAtUtc, _nowMs);
  });

  test('migration v5 to v6 adds level and preferred_level columns', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v6');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v5 = текущая схема без уровней CEFR.
    final v5 = AppDatabase.forTesting(NativeDatabase(file));
    await v5
        .into(v5.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'book',
            translation: 'книга',
          ),
        );
    await v5
        .into(v5.userSettingsTable)
        .insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            updatedAtUtc: _nowMs,
          ),
        );
    await v5.customStatement('ALTER TABLE words DROP COLUMN level');
    await v5.customStatement(
      'ALTER TABLE user_settings DROP COLUMN preferred_level',
    );
    await v5.customStatement('DROP TABLE cloze_tasks');
    await v5.customStatement('PRAGMA user_version = 5');
    await v5.close();

    final v6 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v6.close);

    // DEFAULT 'a1' в DDL: старые строки получают A1, а не пустую строку.
    final word = (await v6.select(v6.words).get()).single;
    expect(word.level, 'a1');
    final settings = (await v6.select(v6.userSettingsTable).get()).single;
    expect(settings.preferredLevel, 'a1');
  });

  test('migration v6 to v7 creates the cloze_tasks table', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v7');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v6 = текущая схема без кэша заданий.
    final v6 = AppDatabase.forTesting(NativeDatabase(file));
    await v6
        .into(v6.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'apple',
            translation: 'яблоко',
          ),
        );
    await v6.customStatement('DROP TABLE cloze_tasks');
    await v6.customStatement('PRAGMA user_version = 6');
    await v6.close();

    final v7 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v7.close);

    // Таблица создана миграцией: запрос не падает и возвращает пусто.
    expect(await v7.select(v7.clozeTasks).get(), isEmpty);
    // Данные v6 пережили миграцию.
    expect((await v7.select(v7.words).get()).single.term, 'apple');
  });

  test('migration v7 to v8 creates the daily_challenges table', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v8');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v7 = текущая схема без ежедневных заданий.
    final v7 = AppDatabase.forTesting(NativeDatabase(file));
    await v7
        .into(v7.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'apple',
            translation: 'яблоко',
          ),
        );
    await v7.customStatement('DROP TABLE daily_challenges');
    await v7.customStatement('PRAGMA user_version = 7');
    await v7.close();

    final v8 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v8.close);

    // Таблица создана миграцией: запрос не падает и возвращает пусто.
    expect(await v8.select(v8.dailyChallenges).get(), isEmpty);
    // Данные v7 пережили миграцию.
    expect((await v8.select(v8.words).get()).single.term, 'apple');
  });

  test('migration v8 to v9 creates challenge_streaks', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v9');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v8 = текущая схема без серии выполненных заданий.
    final v8 = AppDatabase.forTesting(NativeDatabase(file));
    await v8
        .into(v8.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'apple',
            translation: 'яблоко',
          ),
        );
    await v8.customStatement('DROP TABLE challenge_streaks');
    await v8.customStatement('PRAGMA user_version = 8');
    await v8.close();

    final v9 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v9.close);

    // Таблица создана миграцией: запрос не падает и возвращает пусто.
    expect(await v9.select(v9.challengeStreaks).get(), isEmpty);
    // Данные v8 пережили миграцию.
    expect((await v9.select(v9.words).get()).single.term, 'apple');
  });

  test('creates all ten tables on open', () async {
    expect(await db.select(db.words).get(), isEmpty);
    expect(await db.select(db.wordProgresses).get(), isEmpty);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect(await db.select(db.userSettingsTable).get(), isEmpty);
    expect(await db.select(db.dailyStatsTable).get(), isEmpty);
    expect(await db.select(db.frozenDays).get(), isEmpty);
    expect(await db.select(db.wordHints).get(), isEmpty);
    expect(await db.select(db.clozeTasks).get(), isEmpty);
    expect(await db.select(db.dailyChallenges).get(), isEmpty);
    expect(await db.select(db.challengeStreaks).get(), isEmpty);
  });

  test('migration v1 to v2 creates the frozen_days table', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v1 = текущая схема без всего, что добавили v2 и v3: DDL остальных
    // таблиц остаётся настоящим, правим только отличия версий.
    final v1 = AppDatabase.forTesting(NativeDatabase(file));
    await v1.customStatement('DROP TABLE frozen_days');
    await v1.customStatement('DROP TABLE word_hints');
    await v1.customStatement('ALTER TABLE words DROP COLUMN category');
    await v1.customStatement('ALTER TABLE words DROP COLUMN level');
    await v1.customStatement(
      'ALTER TABLE user_settings DROP COLUMN preferred_level',
    );
    await v1
        .into(v1.dailyStatsTable)
        .insert(
          DailyStatsTableCompanion.insert(dateEpochDays: const Value(19723)),
        );
    await v1.customStatement(
      'ALTER TABLE user_settings DROP COLUMN has_seen_onboarding',
    );
    await v1.customStatement('DROP TABLE cloze_tasks');
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v2 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v2.close);

    // Таблица создана миграцией: запрос не падает и возвращает пусто.
    expect(await v2.select(v2.frozenDays).get(), isEmpty);
    // Данные v1 пережили миграцию.
    expect(await v2.select(v2.dailyStatsTable).get(), hasLength(1));
  });

  test('migration v2 to v3 adds the category column', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration_v3');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v2 = текущая схема без words.category.
    final v2 = AppDatabase.forTesting(NativeDatabase(file));
    await v2
        .into(v2.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'book',
            translation: 'книга',
          ),
        );
    await v2.customStatement('DROP TABLE word_hints');
    await v2.customStatement('ALTER TABLE words DROP COLUMN category');
    await v2.customStatement('ALTER TABLE words DROP COLUMN level');
    await v2.customStatement(
      'ALTER TABLE user_settings DROP COLUMN preferred_level',
    );
    await v2.customStatement(
      'ALTER TABLE user_settings DROP COLUMN has_seen_onboarding',
    );
    await v2.customStatement('DROP TABLE cloze_tasks');
    await v2.customStatement('PRAGMA user_version = 2');
    await v2.close();

    final v3 = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(v3.close);

    final row = (await v3.select(v3.words).get()).single;
    // Колонка появилась миграцией и у старой строки она null.
    expect(row.category, isNull);
    expect(row.term, 'book');
  });

  test('inserts and reads a word with every column', () async {
    await db
        .into(db.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'hello',
            translation: 'привет',
            transcription: const Value('/həˈləʊ/'),
            partOfSpeech: const Value('noun'),
            exampleSentence: const Value('Hello, world!'),
          ),
        );

    final words = await db.select(db.words).get();
    expect(words, hasLength(1));
    final word = words.single;
    expect(word.id, 1);
    expect(word.term, 'hello');
    expect(word.translation, 'привет');
    expect(word.transcription, '/həˈləʊ/');
    expect(word.partOfSpeech, 'noun');
    expect(word.exampleSentence, 'Hello, world!');
  });

  test('deletes progress together with its word (cascade)', () async {
    await insertWord(db, 1);
    await insertProgress(db, 1);
    expect(await db.select(db.wordProgresses).get(), hasLength(1));

    await (db.delete(db.words)..where((t) => t.id.equals(1))).go();

    expect(await db.select(db.words).get(), isEmpty);
    expect(await db.select(db.wordProgresses).get(), isEmpty);
  });

  test('keeps review logs after the word is deleted', () async {
    await insertWord(db, 1);
    await insertLog(db, 1);

    await (db.delete(db.words)..where((t) => t.id.equals(1))).go();

    final logs = await db.select(db.reviewLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.wordId, 1);
  });

  test('allows only one user settings row', () async {
    await db
        .into(db.userSettingsTable)
        .insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            updatedAtUtc: _nowMs,
          ),
        );
    expect(await db.select(db.userSettingsTable).get(), hasLength(1));

    await expectLater(
      db
          .into(db.userSettingsTable)
          .insert(
            UserSettingsTableCompanion.insert(
              id: const Value(2),
              updatedAtUtc: _nowMs,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rejects duplicate daily stats for the same day', () async {
    await db
        .into(db.dailyStatsTable)
        .insert(
          DailyStatsTableCompanion.insert(dateEpochDays: const Value(19723)),
        );
    expect(await db.select(db.dailyStatsTable).get(), hasLength(1));

    await expectLater(
      db
          .into(db.dailyStatsTable)
          .insert(
            DailyStatsTableCompanion.insert(dateEpochDays: const Value(19723)),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}
