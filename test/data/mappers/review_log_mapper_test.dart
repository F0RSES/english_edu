import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/review_log_mapper.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

ReviewLog log({int id = 1, ReviewGrade grade = ReviewGrade.good}) => ReviewLog(
  id: ReviewLogId(id),
  wordId: const WordId(1),
  reviewedAt: now,
  grade: grade,
  previousCardState: CardState.initial(now),
  newCardState: CardState.initial(now)
      .copyWith(intervalDays: 6, repetitions: 2),
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('round-trips a log with both card snapshots', () async {
    final original = log();

    await db.into(db.reviewLogs).insert(ReviewLogMapper.toCompanion(original));
    final row = (await db.select(db.reviewLogs).get()).single;

    expect(ReviewLogMapper.toDomain(row), original);
  });

  test('keeps every grade value', () async {
    for (var index = 0; index < ReviewGrade.values.length; index++) {
      await db
          .into(db.reviewLogs)
          .insert(
            ReviewLogMapper.toCompanion(
              log(id: index + 1, grade: ReviewGrade.values[index]),
            ),
          );
    }

    final rows = await db.select(db.reviewLogs).get();
    expect(rows, hasLength(4));
    for (final row in rows) {
      final restored = ReviewLogMapper.toDomain(row);
      expect(restored.grade, ReviewGrade.values[row.id - 1]);
    }
  });

  test('stores prev and new states independently', () async {
    final original = log();
    await db.into(db.reviewLogs).insert(ReviewLogMapper.toCompanion(original));
    final row = (await db.select(db.reviewLogs).get()).single;

    expect(row.prevIntervalDays, 0);
    expect(row.newIntervalDays, 6);
    expect(row.prevRepetitions, 0);
    expect(row.newRepetitions, 2);
  });
}
