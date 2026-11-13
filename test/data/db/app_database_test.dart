import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:test/test.dart';

const _nowMs = 1715774400000; // 2024-05-15T12:00:00Z

AppDatabase openDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> insertWord(AppDatabase db, int id, {String term = 'hello'}) =>
    db.into(db.words).insert(
          WordsCompanion.insert(
            id: Value(id),
            term: term,
            translation: 'привет',
          ),
        );

Future<void> insertProgress(AppDatabase db, int wordId) =>
    db.into(db.wordProgresses).insert(
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

Future<void> insertLog(AppDatabase db, int wordId) =>
    db.into(db.reviewLogs).insert(
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

  test('creates all five tables on open', () async {
    expect(await db.select(db.words).get(), isEmpty);
    expect(await db.select(db.wordProgresses).get(), isEmpty);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect(await db.select(db.userSettingsTable).get(), isEmpty);
    expect(await db.select(db.dailyStatsTable).get(), isEmpty);
  });

  test('inserts and reads a word with every column', () async {
    await db.into(db.words).insert(
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
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            updatedAtUtc: _nowMs,
          ),
        );
    expect(await db.select(db.userSettingsTable).get(), hasLength(1));

    await expectLater(
      db.into(db.userSettingsTable).insert(
            UserSettingsTableCompanion.insert(
              id: const Value(2),
              updatedAtUtc: _nowMs,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rejects duplicate daily stats for the same day', () async {
    await db.into(db.dailyStatsTable).insert(
          DailyStatsTableCompanion.insert(
            dateEpochDays: const Value(19723),
          ),
        );
    expect(await db.select(db.dailyStatsTable).get(), hasLength(1));

    await expectLater(
      db.into(db.dailyStatsTable).insert(
            DailyStatsTableCompanion.insert(
              dateEpochDays: const Value(19723),
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}
