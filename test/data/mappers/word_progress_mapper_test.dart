import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/word_mapper.dart';
import 'package:english_edu/data/mappers/word_progress_mapper.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Future<void> seedWord(AppDatabase db, int id) => db.into(db.words).insert(
      WordMapper.toCompanion(
        domain.Word(id: WordId(id), term: 'w$id', translation: 'п$id'),
      ),
    );

WordProgress progress({
  int wordId = 1,
  WordStatus status = WordStatus.learning,
  DateTime? lastReviewedAt,
}) =>
    WordProgress(
      wordId: WordId(wordId),
      cardState: CardState.initial(now),
      status: status,
      firstSeenAt: now,
      lastReviewedAt: lastReviewedAt,
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('round-trips progress through the database', () async {
    await seedWord(db, 1);
    final original = progress(lastReviewedAt: now);

    await db.into(db.wordProgresses).insert(
          WordProgressMapper.toCompanion(original),
        );
    final row = (await db.select(db.wordProgresses).get()).single;

    expect(WordProgressMapper.toDomain(row), original);
  });

  test('keeps lastReviewedAt null and all statuses', () async {
    for (var index = 0; index < WordStatus.values.length; index++) {
      final id = index + 1;
      await seedWord(db, id);
      final original = progress(
        wordId: id,
        status: WordStatus.values[index],
      );
      await db.into(db.wordProgresses).insert(
            WordProgressMapper.toCompanion(original),
          );
    }

    final rows = await db.select(db.wordProgresses).get();
    expect(rows, hasLength(3));
    for (final row in rows) {
      final restored = WordProgressMapper.toDomain(row);
      expect(restored.status, WordStatus.values[row.wordId - 1]);
      expect(restored.lastReviewedAt, isNull);
    }
  });

  test('rejects progress for a word that does not exist', () async {
    await expectLater(
      db.into(db.wordProgresses).insert(
            WordProgressMapper.toCompanion(progress(wordId: 99)),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
