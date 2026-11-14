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

  test('creates all six tables on open', () async {
    expect(await db.select(db.words).get(), isEmpty);
    expect(await db.select(db.wordProgresses).get(), isEmpty);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect(await db.select(db.userSettingsTable).get(), isEmpty);
    expect(await db.select(db.dailyStatsTable).get(), isEmpty);
    expect(await db.select(db.frozenDays).get(), isEmpty);
  });

  test('migration v1 to v2 creates the frozen_days table', () async {
    final dir = Directory.systemTemp.createTempSync('english_edu_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    // v1 = текущая схема без всего, что добавили v2 и v3: DDL остальных
    // таблиц остаётся настоящим, правим только отличия версий.
    final v1 = AppDatabase.forTesting(NativeDatabase(file));
    await v1.customStatement('DROP TABLE frozen_days');
    await v1.customStatement('ALTER TABLE words DROP COLUMN category');
    await v1
        .into(v1.dailyStatsTable)
        .insert(
          DailyStatsTableCompanion.insert(dateEpochDays: const Value(19723)),
        );
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
    await v2.customStatement('ALTER TABLE words DROP COLUMN category');
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
