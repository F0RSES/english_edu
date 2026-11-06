import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_progress_repository.dart';
import 'package:english_edu/data/repositories/drift_settings_repository.dart';
import 'package:english_edu/data/repositories/drift_stats_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/get_analytics.dart';
import 'package:english_edu/domain/usecases/get_smart_review_queue.dart';
import 'package:english_edu/domain/usecases/get_today_queue.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Baseline производительности на реальном объёме контента: 2071 слово
/// (столько приходит из `words_v2.json`) и 500 записей прогресса.
///
/// Пороговые значения — не SLA, а сторожевой предел: если запрос стал
/// заметно медленнее, значит выросло число проходов по таблицам (BL-55,
/// BL-79). Замер идёт на in-memory SQLite, то есть без дисковых задержек —
/// на устройстве будет медленнее, но пропорционально.

final now = DateTime.utc(2024, 5, 15, 12);
const wordCount = 2071;
const progressCount = 500;

domain.Word word(int id) => domain.Word(
  id: WordId(id),
  term: 'word$id',
  translation: 'перевод$id',
);

WordProgress progress(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 2500,
    intervalDays: 1,
    repetitions: 1,
    lapses: id % 3,
    dueAt: now,
  ),
  status: WordStatus.learning,
  firstSeenAt: now.subtract(Duration(days: id % 30)),
);

Future<AppDatabase> seededDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await DriftWordRepository(
    db,
  ).insertMany([for (var id = 1; id <= wordCount; id++) word(id)]);
  await DriftProgressRepository(
    db,
  ).replaceAll([for (var id = 1; id <= progressCount; id++) progress(id)]);
  await DriftSettingsRepository(db, clock: () => now).save(
    UserSettings.defaults(),
  );
  return db;
}

/// Замеряет [action] в миллисекундах.
Future<int> measure(Future<void> Function() action) async {
  final watch = Stopwatch()..start();
  await action();
  watch.stop();
  return watch.elapsedMilliseconds;
}

void main() {
  late AppDatabase db;
  late DriftWordRepository words;
  late DriftProgressRepository progressRepo;

  setUp(() async {
    db = await seededDb();
    words = DriftWordRepository(db);
    progressRepo = DriftProgressRepository(db);
  });
  tearDown(() => db.close());

  test('today queue stays under 100 ms', () async {
    final useCase = GetTodayQueue(
      words: words,
      progress: progressRepo,
      settings: DriftSettingsRepository(db, clock: () => now),
      clock: () => now,
    );

    final elapsed = await measure(useCase.call);

    expect(elapsed, lessThan(100), reason: 'getTodayQueue: $elapsed ms');
  });

  test('dictionary search stays under 200 ms', () async {
    final elapsed = await measure(() => words.search('word1500'));

    expect(elapsed, lessThan(200), reason: 'search: $elapsed ms');
  });

  test('smart review queue stays under 500 ms', () async {
    final useCase = GetSmartReviewQueue(
      words: words,
      progress: progressRepo,
      clock: () => now,
    );

    final elapsed = await measure(useCase.call);

    expect(elapsed, lessThan(500), reason: 'smartReview: $elapsed ms');
  });

  test('analytics stays under 300 ms', () async {
    final useCase = GetAnalytics(
      words: words,
      progress: progressRepo,
      stats: DriftStatsRepository(db),
      clock: () => now,
    );

    final elapsed = await measure(useCase.call);

    expect(elapsed, lessThan(300), reason: 'analytics: $elapsed ms');
  });
}
