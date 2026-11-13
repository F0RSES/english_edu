import 'package:english_edu/core/crash_reporter.dart';
import 'package:english_edu/core/logger.dart';
import 'package:english_edu/core/notifications/notification_service.dart';
import 'package:english_edu/core/tts/tts_service.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/export_payload_codec.dart';
import 'package:english_edu/data/repositories/drift_frozen_days_repository.dart';
import 'package:english_edu/data/repositories/drift_progress_repository.dart';
import 'package:english_edu/data/repositories/drift_review_log_repository.dart';
import 'package:english_edu/data/repositories/drift_settings_repository.dart';
import 'package:english_edu/data/repositories/drift_stats_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/data/seed_loader.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/srs/sm2_srs_calculator.dart';
import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/usecases/compute_streak.dart';
import 'package:english_edu/domain/usecases/export_progress.dart';
import 'package:english_edu/domain/usecases/get_today_queue.dart';
import 'package:english_edu/domain/usecases/import_progress.dart';
import 'package:english_edu/domain/usecases/mark_missed_day.dart';
import 'package:english_edu/domain/usecases/record_review.dart';
import 'package:english_edu/domain/usecases/reset_progress.dart';
import 'package:english_edu/domain/usecases/undo_last_review.dart';
import 'package:english_edu/domain/value_objects/daily_goal.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Riverpod providers без codegen.
///
/// `riverpod_annotation` появится в 2a.3 (BL-26). Несколько провайдеров
/// намеренно не реализованы и переопределяются в `main`/тестах: база данных,
/// источник идентификаторов логов и отчётчик сбоев.

/// Озвучивание слов.
///
/// В тестах переопределяется на фейк: реальный плагин требует платформенного
/// канала.
final ttsProvider = Provider<TtsService>(
  (ref) => FlutterTtsService(FlutterTts()),
);

/// Логгер приложения.
final loggerProvider = Provider<Logger>((ref) => const DebugLogger());

/// Локальные напоминания. Переопределяется в `main` (ADR-017).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Override notificationServiceProvider in main');
});

/// Отчётчик сбоев. Переопределяется в `main` (ADR-016).
///
/// По умолчанию не реализован намеренно: без явного выбора между Sentry и
/// заглушкой сбой ушёл бы «в никуда» молча.
final crashReporterProvider = Provider<CrashReporter>((ref) {
  throw UnimplementedError('Override crashReporterProvider in main');
});

/// Открытая база данных приложения. Переопределяется в `main`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override appDatabaseProvider in main');
});

/// Часы приложения. В тестах переопределяются на фиксированные.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Бандл ассетов. Переопределяется в тестах, чтобы подменить seed-файл.
final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

/// Источник идентификаторов журнала. Переопределяется в `main`.
///
/// В `main` подставляется `NextReviewLogIdGenerator(maxId + 1)` (ADR-009).
/// После `ImportProgress` счётчик нужно пересчитать: провайдер инвалидируется
/// и создаётся заново от нового `max(id)`. Пока импорт в UI не вызывается —
/// пересчёт отложен до Phase 5 (BL-36).
final nextReviewLogIdProvider = Provider<ReviewLogId Function()>((ref) {
  throw UnimplementedError('Override nextReviewLogIdProvider in main');
});

/// Реализация SM-2.
final srsCalculatorProvider = Provider<SrsCalculator>(
  (ref) => const Sm2SrsCalculator(),
);

/// Доступ к словарю.
final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => DriftWordRepository(ref.watch(appDatabaseProvider)),
);

/// Доступ к прогрессу.
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => DriftProgressRepository(ref.watch(appDatabaseProvider)),
);

/// Доступ к журналу ответов.
final reviewLogRepositoryProvider = Provider<ReviewLogRepository>(
  (ref) => DriftReviewLogRepository(ref.watch(appDatabaseProvider)),
);

/// Доступ к настройкам.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Доступ к дневной статистике.
final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => DriftStatsRepository(ref.watch(appDatabaseProvider)),
);

/// Доступ к заморозкам серии (ADR-015).
final frozenDaysRepositoryProvider = Provider<FrozenDaysRepository>(
  (ref) => DriftFrozenDaysRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Пометка пропущенного дня заморозкой (ADR-015).
final markMissedDayProvider = Provider<MarkMissedDay>(
  (ref) => MarkMissedDay(frozen: ref.watch(frozenDaysRepositoryProvider)),
);

/// Загрузчик seed-контента.
final seedLoaderProvider = Provider<SeedLoader>(
  (ref) => JsonSeedLoader(
    words: ref.watch(wordRepositoryProvider),
    bundle: ref.watch(assetBundleProvider),
  ),
);

/// Очередь на сегодня: use case.
///
/// Отдельно от [getTodayQueueProvider], чтобы тесты подменяли реализацию
/// (`overrideWithValue`) без пересчёта async-состояния.
final getTodayQueueUseCaseProvider = Provider<GetTodayQueue>(
  (ref) => GetTodayQueue(
    words: ref.watch(wordRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Очередь на сегодня как async-данные экрана.
///
/// `FutureProvider`, а не будущий объект в `build`: состоянием владеет
/// провайдер, поэтому `ref.invalidate` действительно запускает пересчёт —
/// иначе главный экран показывал бы прогресс до урока.
final getTodayQueueProvider = FutureProvider<TodayQueue>(
  (ref) => ref.watch(getTodayQueueUseCaseProvider)(),
);

/// Запись ответа.
final recordReviewProvider = Provider<RecordReview>(
  (ref) => RecordReview(
    progress: ref.watch(progressRepositoryProvider),
    reviewLog: ref.watch(reviewLogRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    words: ref.watch(wordRepositoryProvider),
    srs: ref.watch(srsCalculatorProvider),
    nextLogId: ref.watch(nextReviewLogIdProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Расчёт серии: use case.
///
/// Отдельно от [computeStreakProvider] — тесты подменяют реализацию.
final computeStreakUseCaseProvider = Provider<ComputeStreak>(
  (ref) => ComputeStreak(
    stats: ref.watch(statsRepositoryProvider),
    frozen: ref.watch(frozenDaysRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Серия дней как async-данные экрана.
///
/// `FutureProvider`: кэшем владеет провайдер, `ref.invalidate` пересчитывает
/// серию после урока.
final computeStreakProvider = FutureProvider<StreakInfo>(
  (ref) => ref.watch(computeStreakUseCaseProvider)(),
);

/// План и факт ответов на сегодня.
///
/// Статистика дня и настройки читаются параллельно: карточке цели нужны оба
/// значения, а последовательное ожидание удвоило бы время до первого кадра.
final dailyGoalProvider = FutureProvider<DailyGoal>((ref) async {
  final today = LocalDate.fromDateTime(ref.watch(clockProvider)().toLocal());
  final results = await Future.wait<Object?>([
    ref.watch(statsRepositoryProvider).getForDate(today),
    ref.watch(settingsRepositoryProvider).get(),
  ]);
  final settings = results[1]! as UserSettings;
  return DailyGoal(
    stats: results[0] as DailyStats?,
    target: settings.dailyNewLimit + settings.dailyReviewLimit,
  );
});

/// Экспорт состояния.
final exportProgressProvider = Provider<ExportProgress>(
  (ref) => ExportProgress(
    settings: ref.watch(settingsRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
    reviewLog: ref.watch(reviewLogRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    words: ref.watch(wordRepositoryProvider),
    frozen: ref.watch(frozenDaysRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// JSON-кодек снимка состояния (схема v2; v1 читается с пустыми frozenDays).
///
/// Живёт в data-слое, но экраны получают его через DI: presentation не должен
/// импортировать data напрямую.
final payloadCodecProvider = Provider<ExportPayloadCodec>(
  (ref) => const ExportPayloadCodec(),
);

/// Сброс прогресса обучения (ADR-013).
final resetProgressProvider = Provider<ResetProgress>(
  (ref) => ResetProgress(
    progress: ref.watch(progressRepositoryProvider),
    reviewLog: ref.watch(reviewLogRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    frozen: ref.watch(frozenDaysRepositoryProvider),
  ),
);

/// Импорт состояния.
final importProgressProvider = Provider<ImportProgress>(
  (ref) => ImportProgress(
    words: ref.watch(wordRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
    reviewLog: ref.watch(reviewLogRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    frozen: ref.watch(frozenDaysRepositoryProvider),
  ),
);

/// Поисковый запрос словаря.
///
/// Riverpod 3: `StateProvider` ушёл в legacy, поэтому используется `Notifier`.
final class DictionarySearchQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Заменяет текущий запрос.
  // Намеренно не сеттер: вызов из UI не должен читаться как присваивание
  // состояния виджета, а `set query` для Notifier выглядит именно так.
  // ignore: use_setters_to_change_properties
  void update(String value) => state = value;
}

/// Текст поиска по словарю.
final dictionarySearchQueryProvider =
    NotifierProvider<DictionarySearchQuery, String>(DictionarySearchQuery.new);

/// Словарь с прогрессом по каждому слову.
///
/// Поиск идёт через контракт `WordRepository.search`, а не локальным фильтром:
/// правило сравнения живёт в data-слое.
final dictionaryEntriesProvider = FutureProvider<List<DictionaryEntry>>((
  ref,
) async {
  final query = ref.watch(dictionarySearchQueryProvider);
  final wordsRepo = ref.watch(wordRepositoryProvider);
  final words = query.isEmpty
      ? await wordsRepo.getAll()
      : await wordsRepo.search(query);
  final progress = await ref.watch(progressRepositoryProvider).getAll();
  final statusById = {for (final item in progress) item.wordId: item.status};
  return [
    for (final word in words)
      DictionaryEntry(word: word, status: statusById[word.id]),
  ];
});

/// Откат последнего ответа в активной сессии (ADR-010).
final undoLastReviewProvider = Provider<UndoLastReview>(
  (ref) => UndoLastReview(
    progress: ref.watch(progressRepositoryProvider),
    reviewLog: ref.watch(reviewLogRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
  ),
);
