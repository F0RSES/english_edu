import 'dart:math';

import 'package:english_edu/core/crash_reporter.dart';
import 'package:english_edu/core/logger.dart';
import 'package:english_edu/core/notifications/notification_service.dart';
import 'package:english_edu/core/tts/tts_service.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/db/phrase_seed_loader.dart';
import 'package:english_edu/data/db/story_seed_loader.dart';
import 'package:english_edu/data/export_payload_codec.dart';
import 'package:english_edu/data/repositories/drift_achievement_repository.dart';
import 'package:english_edu/data/repositories/drift_challenge_streak_repository.dart';
import 'package:english_edu/data/repositories/drift_chat_repository.dart';
import 'package:english_edu/data/repositories/drift_cloze_task_repository.dart';
import 'package:english_edu/data/repositories/drift_daily_challenge_repository.dart';
import 'package:english_edu/data/repositories/drift_frozen_days_repository.dart';
import 'package:english_edu/data/repositories/drift_phrase_repository.dart';
import 'package:english_edu/data/repositories/drift_progress_repository.dart';
import 'package:english_edu/data/repositories/drift_review_log_repository.dart';
import 'package:english_edu/data/repositories/drift_settings_repository.dart';
import 'package:english_edu/data/repositories/drift_stats_repository.dart';
import 'package:english_edu/data/repositories/drift_story_repository.dart';
import 'package:english_edu/data/repositories/drift_typing_record_repository.dart';
import 'package:english_edu/data/repositories/drift_user_category_repository.dart';
import 'package:english_edu/data/repositories/drift_word_hint_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/data/seed_loader.dart';
import 'package:english_edu/data/sync/supabase_cloud_auth_service.dart';
import 'package:english_edu/data/sync/supabase_cloud_sync_service.dart';
import 'package:english_edu/data/sync/supabase_remote_progress_store.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/phrase.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/repositories/achievement_repository.dart';
import 'package:english_edu/domain/repositories/challenge_streak_repository.dart';
import 'package:english_edu/domain/repositories/chat_repository.dart';
import 'package:english_edu/domain/repositories/cloze_task_repository.dart';
import 'package:english_edu/domain/repositories/daily_challenge_repository.dart';
import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/repositories/phrase_repository.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/repositories/story_repository.dart';
import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/repositories/user_category_repository.dart';
import 'package:english_edu/domain/repositories/word_hint_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/services/chat_generator.dart';
import 'package:english_edu/domain/services/cloud_auth_service.dart';
import 'package:english_edu/domain/services/cloud_sync_service.dart';
import 'package:english_edu/domain/services/cloze_generator.dart';
import 'package:english_edu/domain/services/error_explainer.dart';
import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/services/hint_generator.dart';
import 'package:english_edu/domain/srs/sm2_srs_calculator.dart';
import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/usecases/check_achievements.dart';
import 'package:english_edu/domain/usecases/claim_daily_challenge.dart';
import 'package:english_edu/domain/usecases/compute_streak.dart';
import 'package:english_edu/domain/usecases/create_user_category.dart';
import 'package:english_edu/domain/usecases/explain_error.dart';
import 'package:english_edu/domain/usecases/export_progress.dart';
import 'package:english_edu/domain/usecases/extract_unknown_words.dart';
import 'package:english_edu/domain/usecases/flip_memory_card.dart';
import 'package:english_edu/domain/usecases/generate_dictation_queue.dart';
import 'package:english_edu/domain/usecases/generate_error_task.dart';
import 'package:english_edu/domain/usecases/generate_memory_game.dart';
import 'package:english_edu/domain/usecases/generate_scramble_puzzles.dart';
import 'package:english_edu/domain/usecases/generate_typing_session.dart';
import 'package:english_edu/domain/usecases/get_analytics.dart';
import 'package:english_edu/domain/usecases/get_cloze_task.dart';
import 'package:english_edu/domain/usecases/get_or_create_daily_challenge.dart';
import 'package:english_edu/domain/usecases/get_smart_review_queue.dart';
import 'package:english_edu/domain/usecases/get_today_queue.dart';
import 'package:english_edu/domain/usecases/get_user_categories.dart';
import 'package:english_edu/domain/usecases/get_weak_words_queue.dart';
import 'package:english_edu/domain/usecases/get_word_hint.dart';
import 'package:english_edu/domain/usecases/import_progress.dart';
import 'package:english_edu/domain/usecases/mark_missed_day.dart';
import 'package:english_edu/domain/usecases/record_review.dart';
import 'package:english_edu/domain/usecases/reset_progress.dart';
import 'package:english_edu/domain/usecases/save_typing_record.dart';
import 'package:english_edu/domain/usecases/send_chat_message.dart';
import 'package:english_edu/domain/usecases/submit_typing_answer.dart';
import 'package:english_edu/domain/usecases/undo_last_review.dart';
import 'package:english_edu/domain/usecases/update_challenge_progress.dart';
import 'package:english_edu/domain/usecases/update_challenge_streak.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/analytics.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_goal.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/smart_review_item.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:http/http.dart' as http;
import 'package:stts/stts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Riverpod providers без codegen.
///
/// `riverpod_annotation` появится в 2a.3 (BL-26). Несколько провайдеров
/// намеренно не реализованы и переопределяются в `main`/тестах: база данных,
/// источник идентификаторов логов и отчётчик сбоев.

/// Озвучивание слов.
///
/// В тестах переопределяется на фейк: реальный плагин требует платформенного
/// канала.
final ttsProvider = Provider<TtsService>((ref) => SttsTtsService(Tts()));

/// Пройден ли онбординг (BL-61).
///
/// Начальное значение приходит из `bootstrapApp` (override в `main`), экран
/// онбординга выставляет `true` перед переходом на главную. Роутер читает
/// значение через `ref.read` в `redirect`, поэтому видит его сразу.
final class OnboardingSeen extends Notifier<bool> {
  /// Создаёт notifier; [seeded] — значение из БД на старте.
  OnboardingSeen({bool seeded = false}) : _seeded = seeded;

  final bool _seeded;

  @override
  bool build() => _seeded;

  /// Помечает онбординг пройденным.
  void markSeen() => state = true;
}

/// Флаг «онбординг пройден».
final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(
  OnboardingSeen.new,
);

/// Клиент AI-подсказок (ADR-019). Сеть — только по явному действию.
final aiClientProvider = Provider<AiClient>((ref) => AiClient(http.Client()));

/// Генератор подсказок: реализация — `AiClient` (ADR-019).
///
/// Домен зависит от интерфейса, поэтому `http` в domain не протекает.
final hintGeneratorProvider = Provider<HintGenerator>(
  (ref) => ref.watch(aiClientProvider),
);

/// Генератор заданий мини-игры; реализация — `AiClient` (Phase 8).
final errorTaskGeneratorProvider = Provider<ErrorTaskGenerator>(
  (ref) => ref.watch(aiClientProvider),
);

/// Задание «Охоты на ошибки» с повторными попытками (Phase 26a).
final generateErrorTaskProvider = Provider<GenerateErrorTask>(
  (ref) => GenerateErrorTask(generator: ref.watch(errorTaskGeneratorProvider)),
);

/// Генератор заданий «Заполни пропуск»; реализация — `AiClient` (ADR-025).
final clozeGeneratorProvider = Provider<ClozeGenerator>(
  (ref) => ref.watch(aiClientProvider),
);

/// Генератор ответов чата; реализация — `AiClient` (ADR-041).
final chatGeneratorProvider = Provider<ChatGenerator>(
  (ref) => ref.watch(aiClientProvider),
);

/// Объяснение ошибок в играх; реализация — `AiClient` (ADR-042).
final errorExplainerProvider = Provider<ErrorExplainer>(
  (ref) => ref.watch(aiClientProvider),
);

/// Кэш заданий «Заполни пропуск» (ADR-025, schema v7).
final clozeTaskRepositoryProvider = Provider<ClozeTaskRepository>(
  (ref) => DriftClozeTaskRepository(ref.watch(appDatabaseProvider)),
);

/// Задание «Заполни пропуск»: кэш → AI → кэш (ADR-025).
final getClozeTaskProvider = Provider<GetClozeTask>(
  (ref) => GetClozeTask(
    tasks: ref.watch(clozeTaskRepositoryProvider),
    generator: ref.watch(clozeGeneratorProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Хранилище AI-подсказок (ADR-019, schema v4).
final wordHintRepositoryProvider = Provider<WordHintRepository>(
  (ref) => DriftWordHintRepository(ref.watch(appDatabaseProvider)),
);

/// Подсказка к слову: кэш → AI → кэш (ADR-019).
final getWordHintProvider = Provider<GetWordHint>(
  (ref) => GetWordHint(
    hints: ref.watch(wordHintRepositoryProvider),
    generator: ref.watch(hintGeneratorProvider),
    clock: ref.watch(clockProvider),
  ),
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

/// Хранилище ежедневных заданий (ADR-030, schema v8).
final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>(
  (ref) => DriftDailyChallengeRepository(ref.watch(appDatabaseProvider)),
);

/// Задание дня: возвращает существующее или создаёт новое (ADR-030).
final getOrCreateDailyChallengeProvider = Provider<GetOrCreateDailyChallenge>(
  (ref) => GetOrCreateDailyChallenge(
    repo: ref.watch(dailyChallengeRepositoryProvider),
    clock: ref.watch(clockProvider),
    // `Random()` без seed: тип задания должен меняться от дня ко дню.
    random: Random(),
  ),
);

/// Прогресс задания дня после ответа (ADR-030).
final updateChallengeProgressProvider = Provider<UpdateChallengeProgress>(
  (ref) => UpdateChallengeProgress(
    repo: ref.watch(dailyChallengeRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Награда за выполненное задание дня (ADR-030).
final claimDailyChallengeProvider = Provider<ClaimDailyChallenge>(
  (ref) => ClaimDailyChallenge(
    challenges: ref.watch(dailyChallengeRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    streaks: ref.watch(updateChallengeStreakProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Smart Review: ранжированная очередь повтора (ADR-033).
final getSmartReviewQueueProvider = Provider<GetSmartReviewQueue>(
  (ref) => GetSmartReviewQueue(
    words: ref.watch(wordRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Очередь умного повторения с причинами.
final smartReviewQueueProvider = FutureProvider<List<SmartReviewItem>>(
  (ref) => ref.watch(getSmartReviewQueueProvider)(),
);

/// Сколько слов попадёт в умное повторение — для бейджа на главной.
final smartReviewCountProvider = FutureProvider<int>(
  (ref) async => (await ref.watch(smartReviewQueueProvider.future)).length,
);

/// Умное повторение как очередь урока.
///
/// `LessonScreen` работает с `TodayQueue`, поэтому причины и score остаются
/// в domain-провайдере, а экран получает привычный тип. `newWords` пуст: это
/// режим повторения.
final smartReviewTodayQueueProvider = FutureProvider<TodayQueue>((ref) async {
  final items = await ref.watch(smartReviewQueueProvider.future);
  return TodayQueue(
    due: [for (final item in items) item.word],
    newWords: const [],
  );
});

/// Хранилище серии выполненных заданий (ADR-032, schema v9).
final challengeStreakRepositoryProvider = Provider<ChallengeStreakRepository>(
  (ref) => DriftChallengeStreakRepository(ref.watch(appDatabaseProvider)),
);

/// Обновление серии при выдаче награды (ADR-032).
final updateChallengeStreakProvider = Provider<UpdateChallengeStreak>(
  (ref) => UpdateChallengeStreak(
    repo: ref.watch(challengeStreakRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Серия выполненных заданий как async-данные карточки.
///
/// Пустое хранилище отдаётся нулевой серией: бейджу нужно число, а не
/// обработка null в виджете.
final challengeStreakProvider = FutureProvider<ChallengeStreak>(
  (ref) async =>
      await ref.watch(challengeStreakRepositoryProvider).get() ??
      ChallengeStreak.empty(DateTime.utc(1970)),
);

/// Задание дня как async-данные главного экрана.
///
/// `FutureProvider`, а не future из `build`: после награды `ref.invalidate`
/// перечитывает задание, и карточка показывает «Выполнено».
final dailyChallengeProvider = FutureProvider<DailyChallenge>(
  (ref) => ref.watch(getOrCreateDailyChallengeProvider)(),
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
    challengeProgress: ref.watch(updateChallengeProgressProvider),
    checkAchievements: ref.watch(checkAchievementsProvider),
  ),
);

/// Проблемные слова для отдельного повторения (ADR-026).
final getWeakWordsQueueProvider = Provider<GetWeakWordsQueue>(
  (ref) => GetWeakWordsQueue(
    words: ref.watch(wordRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
  ),
);

/// Очередь проблемных слов как async-данные урока.
///
/// `FutureProvider`, а не future из `build`: экран урока читает `.future`,
/// а `ref.invalidate` после сессии пересчитывает её.
final weakWordsQueueProvider = FutureProvider<TodayQueue>(
  (ref) => ref.watch(getWeakWordsQueueProvider)(),
);

/// Количество проблемных слов для бейджа на кнопке (ADR-026).
final weakWordsCountProvider = FutureProvider<int>(
  (ref) async => (await ref.watch(weakWordsQueueProvider.future)).due.length,
);

/// Генератор очереди аудио-диктанта (ADR-028).
///
/// `Random()` без seed: порядок слов должен меняться от сессии к сессии.
/// Тесты подменяют провайдер целиком.
final generateDictationQueueProvider = Provider<GenerateDictationQueue>(
  (ref) => GenerateDictationQueue(
    words: ref.watch(wordRepositoryProvider),
    random: Random(),
  ),
);

/// Генератор заданий «Собери слово» (ADR-027).
///
/// `Random()` без seed: в приложении перестановка должна отличаться от раза к
/// разу. Тесты подменяют провайдер целиком, поэтому seed здесь не нужен.
final generateScramblePuzzlesProvider = Provider<GenerateScramblePuzzles>(
  (ref) => GenerateScramblePuzzles(
    words: ref.watch(wordRepositoryProvider),
    random: Random(),
  ),
);

/// Сводка для экрана аналитики (ADR-021).
final getAnalyticsProvider = Provider<GetAnalytics>(
  (ref) => GetAnalytics(
    words: ref.watch(wordRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Аналитика как async-данные экрана.
///
/// `FutureProvider`, а не future из `build`: иначе любой rebuild
/// перезапускал бы три запроса к БД (BL-41).
final analyticsProvider = FutureProvider<Analytics>(
  (ref) => ref.watch(getAnalyticsProvider)(),
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
  (ref) => ExportPayloadCodec(logger: ref.watch(loggerProvider)),
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

/// Сборка партии «Memory» (ADR-036).
///
/// `Random()` без seed: расклад должен меняться от партии к партии.
final generateMemoryGameProvider = Provider<GenerateMemoryGame>(
  (ref) => GenerateMemoryGame(
    words: ref.watch(wordRepositoryProvider),
    random: Random(),
  ),
);

/// Правило хода в «Memory»: чистая функция, состояние приходит снаружи.
final flipMemoryCardProvider = Provider<FlipMemoryCard>(
  (ref) => const FlipMemoryCard(),
);

/// Справочник фраз (ADR-038, schema v13).
final phraseRepositoryProvider = Provider<PhraseRepository>(
  (ref) => DriftPhraseRepository(ref.watch(appDatabaseProvider)),
);

/// Загрузчик фраз из ассетов.
final phraseSeedLoaderProvider = Provider<PhraseSeedLoader>(
  (ref) => PhraseSeedLoader(
    phrases: ref.watch(phraseRepositoryProvider),
    bundle: ref.watch(assetBundleProvider),
  ),
);

/// Фразы для экрана; при первом обращении таблица наполняется из ассетов.
final phrasesProvider = FutureProvider<List<Phrase>>((ref) async {
  final repo = ref.watch(phraseRepositoryProvider);
  await ref.watch(phraseSeedLoaderProvider).load();
  return await repo.getAll();
});

/// Рассказы для чтения (ADR-039, schema v14).
final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => DriftStoryRepository(ref.watch(appDatabaseProvider)),
);

/// Загрузчик рассказов из ассетов.
final storySeedLoaderProvider = Provider<StorySeedLoader>(
  (ref) => StorySeedLoader(
    stories: ref.watch(storyRepositoryProvider),
    bundle: ref.watch(assetBundleProvider),
  ),
);

/// Рассказы для экрана; при первом обращении таблица наполняется из ассетов.
final storiesProvider = FutureProvider<List<Story>>((ref) async {
  await ref.watch(storySeedLoaderProvider).loadIfEmpty();
  return await ref.watch(storyRepositoryProvider).getAll();
});

/// Рассказы одного уровня CEFR.
final FutureProviderFamily<List<Story>, CefrLevel> storiesByLevelProvider =
    FutureProvider.family<List<Story>, CefrLevel>((ref, level) async {
      await ref.watch(storySeedLoaderProvider).loadIfEmpty();
      return await ref.watch(storyRepositoryProvider).getByLevel(level);
    });

/// Незнакомые слова текста рассказа (ADR-039).
final extractUnknownWordsProvider = Provider<ExtractUnknownWords>(
  (ref) => ExtractUnknownWords(words: ref.watch(wordRepositoryProvider)),
);

/// Хранилище рекордов «Typing Speed» (ADR-037, schema v12).
final typingRecordRepositoryProvider = Provider<TypingRecordRepository>(
  (ref) => DriftTypingRecordRepository(ref.watch(appDatabaseProvider)),
);

/// Сборка заезда: 10 случайных слов.
final generateTypingSessionProvider = Provider<GenerateTypingSession>(
  (ref) => GenerateTypingSession(
    words: ref.watch(wordRepositoryProvider),
    random: Random(),
  ),
);

/// Проверка ввода: чистая функция.
final submitTypingAnswerProvider = Provider<SubmitTypingAnswer>(
  (ref) => const SubmitTypingAnswer(),
);

/// Сохранение результата заезда.
final saveTypingRecordProvider = Provider<SaveTypingRecord>(
  (ref) => SaveTypingRecord(
    records: ref.watch(typingRecordRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Лучший результат для AppBar.
final bestTypingRecordProvider = FutureProvider<TypingRecord?>(
  (ref) => ref.watch(typingRecordRepositoryProvider).getBest(),
);

/// Хранилище достижений (ADR-035, schema v11).
final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => DriftAchievementRepository(ref.watch(appDatabaseProvider)),
);

/// Пересчёт достижений после ответа или награды (ADR-035).
final checkAchievementsProvider = Provider<CheckAchievements>(
  (ref) => CheckAchievements(
    achievements: ref.watch(achievementRepositoryProvider),
    stats: ref.watch(statsRepositoryProvider),
    progress: ref.watch(progressRepositoryProvider),
    frozen: ref.watch(frozenDaysRepositoryProvider),
    challengeStreak: ref.watch(challengeStreakRepositoryProvider),
    reviewLogs: ref.watch(reviewLogRepositoryProvider),
    chat: ref.watch(chatRepositoryProvider),
    typing: ref.watch(typingRecordRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Достижения как async-данные экрана.
final achievementsProvider = FutureProvider<List<Achievement>>(
  (ref) => ref.watch(achievementRepositoryProvider).getAll(),
);

/// Хранилище категорий слов (ADR-034, schema v10).
final userCategoryRepositoryProvider = Provider<UserCategoryRepository>(
  (ref) => DriftUserCategoryRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Список категорий для фильтра и диалогов.
final getUserCategoriesProvider = Provider<GetUserCategories>(
  (ref) => GetUserCategories(repo: ref.watch(userCategoryRepositoryProvider)),
);

/// Создание пользовательской категории с проверками имени.
final createUserCategoryProvider = Provider<CreateUserCategory>(
  (ref) => CreateUserCategory(repo: ref.watch(userCategoryRepositoryProvider)),
);

/// Категории как async-данные экрана.
///
/// `FutureProvider`, а не future из `build`: после создания или удаления
/// `ref.invalidate` перечитывает список, и чипы обновляются сразу.
final userCategoriesProvider = FutureProvider<List<UserCategory>>(
  (ref) => ref.watch(getUserCategoriesProvider)(),
);

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

/// История чата с AI-помощником (ADR-041, schema v15).
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => DriftChatRepository(ref.watch(appDatabaseProvider)),
);

/// Отправка сообщения помощнику: последние 10 сообщений в контекст (ADR-041).
final sendChatMessageProvider = Provider<SendChatMessage>(
  (ref) => SendChatMessage(
    chat: ref.watch(chatRepositoryProvider),
    ai: ref.watch(chatGeneratorProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// История чата для экрана; инвалидируется после отправки и очистки.
final chatHistoryProvider = FutureProvider<List<ChatMessage>>(
  (ref) => ref.watch(chatRepositoryProvider).getAll(),
);

/// Объяснение ошибки с уровнем пользователя для тона (ADR-042).
final explainErrorProvider = Provider<ExplainError>(
  (ref) => ExplainError(
    explainer: ref.watch(errorExplainerProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

/// URL проекта Supabase (`--dart-define=SUPABASE_URL=...`, ADR-022).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

/// Публичный anon key Supabase (`--dart-define=SUPABASE_ANON_KEY=...`).
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Настроено ли облако.
///
/// Без ключей приложение работает ровно как раньше: офлайн, без синхронизации.
bool get isCloudConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

/// Настроено ли облако (для провайдеров и тестов).
final isCloudConfiguredProvider = Provider<bool>((ref) => isCloudConfigured);

/// Клиент Supabase или null, когда облако не настроено.
///
/// `Supabase.instance` доступен только после `Supabase.initialize` в `main`,
/// поэтому флаг конфигурации проверяется до обращения к нему.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!ref.watch(isCloudConfiguredProvider)) {
    return null;
  }
  return Supabase.instance.client;
});

/// Авторизация в облаке (ADR-022).
final cloudAuthServiceProvider = Provider<CloudAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnavailableCloudAuthService()
      : SupabaseCloudAuthService(client);
});

/// Email текущего пользователя облака; null — не авторизован.
///
/// Сначала отдаётся сохранённая сессия, затем поток изменений: экран не мигает
/// «войдите» при каждом открытии профиля.
final cloudEmailProvider = StreamProvider<String?>((ref) async* {
  final auth = ref.watch(cloudAuthServiceProvider);
  yield auth.email;
  if (auth.isAvailable) {
    yield* auth.authChanges;
  }
});

/// Синхронизация прогресса с облаком (ADR-022).
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return const UnavailableCloudSyncService();
  }
  return SupabaseCloudSyncService(
    local: ref.watch(progressRepositoryProvider),
    remote: SupabaseRemoteProgressStore(client),
  );
});
