import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/word_progress_mapper.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

domain.Word word(int id, String term) =>
    domain.Word(id: WordId(id), term: term, translation: 'перевод$term');

void main() {
  late AppDatabase db;
  late DriftWordRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftWordRepository(db);
  });
  tearDown(() => db.close());

  test('upserts and reads a word by id', () async {
    await repo.upsert(word(1, 'hello'));

    final found = await repo.getById(const WordId(1));
    expect(found, word(1, 'hello'));
  });

  test('returns null for a missing id', () async {
    expect(await repo.getById(const WordId(42)), isNull);
  });

  test('returns all words', () async {
    await repo.upsert(word(1, 'one'));
    await repo.upsert(word(2, 'two'));

    expect(await repo.getAll(), hasLength(2));
  });

  test('counts words for a cheap emptiness check', () async {
    expect(await repo.count(), 0);

    await repo.insertMany([word(1, 'one'), word(2, 'two')]);

    expect(await repo.count(), 2);
  });

  test('nextId returns 1 on an empty database', () async {
    expect((await repo.nextId()).value, 1);
  });

  test('nextId returns max plus one after inserts', () async {
    await repo.insertMany([word(1, 'one'), word(7, 'seven')]);

    expect((await repo.nextId()).value, 8);
  });

  test('nextId does not reuse a deleted id', () async {
    await repo.insertMany([word(1, 'one'), word(2, 'two'), word(3, 'three')]);
    await repo.delete(const WordId(2));

    expect((await repo.nextId()).value, 4);
  });

  test('reads several ids at once', () async {
    await repo.insertMany([word(1, 'one'), word(2, 'two'), word(3, 'three')]);

    expect(await repo.getByIds(const [WordId(1), WordId(3)]), hasLength(2));
  });

  test('returns empty list for empty ids', () async {
    await repo.upsert(word(1, 'one'));
    expect(await repo.getByIds(const []), isEmpty);
  });

  test('silently skips ids without a word', () async {
    await repo.upsert(word(1, 'one'));

    final found = await repo.getByIds(const [WordId(1), WordId(99)]);
    expect(found, hasLength(1));
    expect(found.single.id.value, 1);
  });

  test('searches case-insensitively by term and translation', () async {
    await repo.insertMany([
      word(1, 'apple'),
      const domain.Word(id: WordId(2), term: 'book', translation: 'Книга'),
    ]);

    expect(await repo.search('  APP  '), hasLength(1));
    expect(await repo.search('Книга'), hasLength(1));
    expect(await repo.search(''), isEmpty);
  });

  test('deletes a word and its progress', () async {
    await repo.upsert(word(1, 'one'));
    await db
        .into(db.wordProgresses)
        .insert(
          WordProgressMapper.toCompanion(
            WordProgress(
              wordId: const WordId(1),
              cardState: CardState.initial(now),
              status: WordStatus.learning,
              firstSeenAt: now,
            ),
          ),
        );

    await repo.delete(const WordId(1));

    expect(await repo.getById(const WordId(1)), isNull);
    expect(await db.select(db.wordProgresses).get(), isEmpty);
  });

  test('inserts a batch atomically', () async {
    await repo.upsert(word(1, 'one'));

    await expectLater(
      repo.insertMany([word(2, 'two'), word(1, 'duplicate')]),
      throwsA(isA<Exception>()),
    );
    expect(await repo.getAll(), hasLength(1));
    expect(await repo.getById(const WordId(2)), isNull);
  });

  test('accepts an empty batch', () async {
    await repo.insertMany(const []);
    expect(await repo.getAll(), isEmpty);
  });

  test('replaces all words', () async {
    await repo.insertMany([word(1, 'one'), word(2, 'two')]);

    await repo.replaceAll([word(3, 'three')]);

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.id.value, 3);
  });
}
