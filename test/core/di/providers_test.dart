import 'package:drift/native.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/di/review_log_id_generator.dart';
import 'package:english_edu/core/tts/tts_service.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/seed_loader.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/usecases/compute_streak.dart';
import 'package:english_edu/domain/usecases/export_progress.dart';
import 'package:english_edu/domain/usecases/get_today_queue.dart';
import 'package:english_edu/domain/usecases/import_progress.dart';
import 'package:english_edu/domain/usecases/record_review.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';

void main() {
  // `rootBundle` в seedLoaderProvider требует инициализированного binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nextReviewLogIdProvider.overrideWithValue(
          NextReviewLogIdGenerator(1).next,
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('all providers resolve without errors', () {
    expect(container.read(clockProvider), isNotNull);
    expect(container.read(wordRepositoryProvider), isNotNull);
    expect(container.read(progressRepositoryProvider), isNotNull);
    expect(container.read(reviewLogRepositoryProvider), isNotNull);
    expect(container.read(settingsRepositoryProvider), isNotNull);
    expect(container.read(statsRepositoryProvider), isNotNull);
    expect(container.read(srsCalculatorProvider), isNotNull);
    expect(container.read(nextReviewLogIdProvider), isNotNull);
  });

  test('appDatabase throws when not overridden', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);

    // Riverpod 3 оборачивает ошибку провайдера в собственный exception
    // (тип не экспортируется), поэтому проверяем текст.
    expect(
      () => bare.read(appDatabaseProvider),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('UnimplementedError'),
        ),
      ),
    );
  });

  test('use cases construct with real dependencies', () {
    expect(container.read(getTodayQueueUseCaseProvider), isA<GetTodayQueue>());
    expect(container.read(recordReviewProvider), isA<RecordReview>());
    expect(container.read(computeStreakUseCaseProvider), isA<ComputeStreak>());
    expect(container.read(exportProgressProvider), isA<ExportProgress>());
    expect(container.read(importProgressProvider), isA<ImportProgress>());
  });

  test('computeStreakProvider exposes async state', () async {
    expect(
      container.read(computeStreakProvider),
      isA<AsyncValue<StreakInfo>>(),
    );

    final streak = await container.read(computeStreakProvider.future);

    expect(streak.count, 0);
    expect(container.read(computeStreakProvider).hasValue, isTrue);
  });

  test('getTodayQueueProvider exposes async state', () async {
    expect(
      container.read(getTodayQueueProvider),
      isA<AsyncValue<TodayQueue>>(),
    );

    final queue = await container.read(getTodayQueueProvider.future);

    expect(queue.all, isEmpty);
    expect(container.read(getTodayQueueProvider).hasValue, isTrue);
  });

  test('dailyGoalProvider sums the daily limits', () async {
    final local = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(
            const UserSettings(dailyNewLimit: 4, dailyReviewLimit: 6),
          ),
        ),
      ],
    );
    addTearDown(local.dispose);

    final goal = await local.read(dailyGoalProvider.future);

    expect(goal.target, 10);
    expect(goal.done, 0);
  });

  test('invalidate recomputes the cached streak', () async {
    final stats = FakeStatsRepository([
      const DailyStats(
        date: LocalDate(20000),
        newWordsStudied: 1,
        reviewsCompleted: 0,
        xpGained: 10,
        correctAnswers: 1,
      ),
    ]);
    final local = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        statsRepositoryProvider.overrideWithValue(stats),
        clockProvider.overrideWithValue(() => DateTime.utc(2024, 10, 4, 12)),
      ],
    );
    addTearDown(local.dispose);

    expect((await local.read(computeStreakProvider.future)).count, 1);

    await stats.upsert(
      const DailyStats(
        date: LocalDate(19999),
        newWordsStudied: 1,
        reviewsCompleted: 0,
        xpGained: 10,
        correctAnswers: 1,
      ),
    );

    // Без invalidate кэш держит прошлое значение — это и был BL-41.
    expect((await local.read(computeStreakProvider.future)).count, 1);

    local.invalidate(computeStreakProvider);

    expect((await local.read(computeStreakProvider.future)).count, 2);
  });

  test('seed loader resolves to the JSON implementation', () {
    expect(container.read(seedLoaderProvider), isA<JsonSeedLoader>());
  });

  test('tts provider resolves to the stts implementation', () {
    expect(container.read(ttsProvider), isA<SttsTtsService>());
  });

  test('asset bundle can be overridden for seeding', () {
    final bundle = _FakeBundle();
    final custom = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        assetBundleProvider.overrideWithValue(bundle),
      ],
    );
    addTearDown(custom.dispose);

    expect(custom.read(assetBundleProvider), same(bundle));
  });
}

/// Минимальный бандл: содержимое не читается, проверяется подмена.
final class _FakeBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(const [123, 125]));
}
