import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_progress_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

final dueAt = DateTime.utc(2024, 5, 15, 12);

domain.Word word(int id) =>
    domain.Word(id: WordId(id), term: 'w$id', translation: 'п$id');

WordProgress progress(
  int wordId, {
  WordStatus status = WordStatus.learning,
  DateTime? due,
}) => WordProgress(
  wordId: WordId(wordId),
  cardState: CardState.initial(due ?? dueAt),
  status: status,
  firstSeenAt: dueAt,
);

void main() {
  late AppDatabase db;
  late DriftProgressRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftProgressRepository(db);
    final words = DriftWordRepository(db);
    await words.insertMany([word(1), word(2), word(3), word(4)]);
  });
  tearDown(() => db.close());

  test('upserts and reads progress by word id', () async {
    await repo.upsert(progress(1));

    expect(await repo.getByWordId(const WordId(1)), progress(1));
  });

  test('returns null for a missing word', () async {
    expect(await repo.getByWordId(const WordId(99)), isNull);
  });

  test('filters by all three statuses', () async {
    await repo.replaceAll([
      progress(1, status: WordStatus.newWord),
      progress(2),
      progress(3, status: WordStatus.mastered),
    ]);

    expect(await repo.getByStatus(WordStatus.newWord), hasLength(1));
    expect(await repo.getByStatus(WordStatus.learning), hasLength(1));
    expect(await repo.getByStatus(WordStatus.mastered), hasLength(1));
  });

  test(
    'returns cards due at or before the instant, including the bound',
    () async {
      await repo.replaceAll([
        progress(1, due: dueAt.subtract(const Duration(hours: 2))),
        progress(2, due: dueAt),
        progress(3, due: dueAt.add(const Duration(hours: 2))),
      ]);

      final due = await repo.getDueBefore(dueAt);
      expect(due.map((item) => item.wordId.value), [1, 2]);
    },
  );

  test('rejects a non-UTC instant', () async {
    await expectLater(
      repo.getDueBefore(DateTime(2024, 5, 15)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('returns every progress record', () async {
    await repo.replaceAll([progress(1), progress(2)]);
    expect(await repo.getAll(), hasLength(2));
  });

  test('replaces all records', () async {
    await repo.replaceAll([progress(1), progress(2)]);
    await repo.replaceAll([progress(3)]);

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.wordId.value, 3);
  });

  test('updates an existing record instead of duplicating', () async {
    await repo.upsert(progress(1));
    await repo.upsert(progress(1, status: WordStatus.mastered));

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.status, WordStatus.mastered);
  });
}
