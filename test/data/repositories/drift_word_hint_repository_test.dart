import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_word_hint_repository.dart';
import 'package:english_edu/domain/value_objects/word_hint.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

WordHint hint({
  int wordId = 1,
  String term = 'hello',
  String text = 'представь приветствие',
  DateTime? createdAtUtc,
}) => WordHint(
  wordId: WordId(wordId),
  term: term,
  hintText: text,
  createdAtUtc: createdAtUtc ?? now,
);

/// Подсказка ссылается на слово внешним ключом — сначала вставляем слово.
Future<void> insertWord(AppDatabase db, int id) => db
    .into(db.words)
    .insert(
      WordsCompanion.insert(
        id: Value(id),
        term: 'term$id',
        translation: 'перевод',
      ),
    );

void main() {
  late AppDatabase db;
  late DriftWordHintRepository hints;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    hints = DriftWordHintRepository(db);
  });
  tearDown(() => db.close());

  test('saves a hint and reads it back', () async {
    await insertWord(db, 1);

    await hints.upsert(hint());

    final stored = await hints.getByWordId(const WordId(1));
    expect(stored, isNotNull);
    expect(stored!.hintText, 'представь приветствие');
    expect(stored.createdAtUtc, now);
    expect(stored.createdAtUtc.isUtc, isTrue);
  });

  test('keeps the term for cache invalidation', () async {
    await insertWord(db, 1);

    await hints.upsert(hint(term: 'helo'));

    expect((await hints.getByWordId(const WordId(1)))!.term, 'helo');
  });

  test('replaces the hint of the same word instead of duplicating', () async {
    await insertWord(db, 1);

    await hints.upsert(hint(text: 'первая'));
    await hints.upsert(hint(text: 'вторая'));

    final rows = await db.select(db.wordHints).get();
    expect(rows, hasLength(1));
    expect(rows.single.hintText, 'вторая');
  });

  test('deletes the hint together with its word (cascade)', () async {
    await insertWord(db, 1);
    await hints.upsert(hint());
    expect(await db.select(db.wordHints).get(), hasLength(1));

    await (db.delete(db.words)..where((t) => t.id.equals(1))).go();

    expect(await db.select(db.wordHints).get(), isEmpty);
    expect(await hints.getByWordId(const WordId(1)), isNull);
  });

  test('returns null for a word without a hint', () async {
    await insertWord(db, 1);

    expect(await hints.getByWordId(const WordId(1)), isNull);
  });

  test('rejects a non-UTC createdAtUtc at the value object', () {
    expect(
      () => hint(createdAtUtc: DateTime(2024, 5, 15, 12)),
      throwsA(isA<AssertionError>()),
    );
  });
}
