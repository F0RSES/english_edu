import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_review_log_repository.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

final base = DateTime.utc(2024, 5, 15, 12);

ReviewLog log(int id, {int wordId = 1, DateTime? at}) => ReviewLog(
      id: ReviewLogId(id),
      wordId: WordId(wordId),
      reviewedAt: at ?? base,
      grade: ReviewGrade.good,
      previousCardState: CardState.initial(base),
      newCardState: CardState.initial(base),
    );

void main() {
  late AppDatabase db;
  late DriftReviewLogRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftReviewLogRepository(db);
  });
  tearDown(() => db.close());

  test('appends and reads entries by word', () async {
    await repo.append(log(1));
    await repo.append(log(2, wordId: 2));

    final entries = await repo.getByWordId(const WordId(1));
    expect(entries, hasLength(1));
    expect(entries.single.id.value, 1);
  });

  test('reads the half-open date range', () async {
    await repo.append(log(1, at: base.subtract(const Duration(hours: 1))));
    await repo.append(log(2, at: base));
    await repo.append(log(3, at: base.add(const Duration(hours: 1))));

    final entries = await repo.getByDateRange(
      base,
      base.add(const Duration(hours: 1)),
    );
    expect(entries.map((entry) => entry.id.value), [2]);
  });

  test('rejects non-UTC bounds', () async {
    await expectLater(
      repo.getByDateRange(DateTime(2024, 5, 15), base),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('returns every entry', () async {
    await repo.append(log(1));
    await repo.append(log(2));

    expect(await repo.getAll(), hasLength(2));
  });

  test('replaces the whole log', () async {
    await repo.append(log(1));
    await repo.append(log(2));

    await repo.replaceAll([log(3)]);

    final entries = await repo.getAll();
    expect(entries, hasLength(1));
    expect(entries.single.id.value, 3);
  });

  test('drops old entries after replaceAll', () async {
    await repo.append(log(1));
    await repo.replaceAll(const []);

    expect(await repo.getAll(), isEmpty);
  });
}
