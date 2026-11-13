import 'package:english_edu/core/crash_reporter.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/di/review_log_id_generator.dart';
import 'package:english_edu/core/logger.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/usecases/compute_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_rule.dart';
import 'package:english_edu/presentation/router.dart';
import 'package:english_edu/presentation/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Результат [bootstrapApp]: генератор id и выбранный отчётчик сбоев.
typedef BootstrapResult = ({
  NextReviewLogIdGenerator idGenerator,
  CrashReporter crashReporter,
});

/// Bootstrap: crash reporting → seed (best effort) → стартовый id журнала.
///
/// Падение seed не блокирует запуск: приложение стартует с пустой БД, seed
/// повторится при следующем запуске (`count() == 0`). Тот же принцип для
/// чтения `MAX(id)`: при ошибке генератор начинается с 1.
///
/// Пустой [sentryDsn] отключает отправку сбоев: возвращается
/// [NoOpCrashReporter] (ADR-016). [sentryInit] инжектится тестами, чтобы не
/// поднимать нативную инициализацию SDK.
Future<BootstrapResult> bootstrapApp({
  required AppDatabase db,
  required AssetBundle bundle,
  required Logger logger,
  required String? sentryDsn,
  Future<void> Function(String dsn)? sentryInit,
}) async {
  final crashReporter = await _initCrashReporter(
    dsn: sentryDsn,
    init: sentryInit,
    logger: logger,
  );

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      assetBundleProvider.overrideWithValue(bundle),
      loggerProvider.overrideWithValue(logger),
      crashReporterProvider.overrideWithValue(crashReporter),
    ],
  );
  try {
    await _seed(container, logger, crashReporter);
    await _coverMissedDay(container, logger);
  } finally {
    container.dispose();
  }

  try {
    final maxRow = await db
        .customSelect('SELECT COALESCE(MAX(id), 0) AS max_id FROM review_logs')
        .getSingle();
    return (
      idGenerator: NextReviewLogIdGenerator(maxRow.read<int>('max_id') + 1),
      crashReporter: crashReporter,
    );
  } on Object catch (error, stack) {
    logger.error('Cannot read max review log id', error, stack);
    await crashReporter.captureException(
      error,
      stackTrace: stack,
      context: 'bootstrap_review_log_id',
    );
    return (
      idGenerator: NextReviewLogIdGenerator(1),
      crashReporter: crashReporter,
    );
  }
}

/// Загружает seed в пустую базу.
///
/// Падение загрузчика не блокирует запуск: база остаётся пустой, seed
/// повторится при следующем старте.
Future<void> _seed(
  ProviderContainer container,
  Logger logger,
  CrashReporter crashReporter,
) async {
  try {
    await container.read(seedLoaderProvider).loadIfEmpty();
  } on Object catch (error, stack) {
    logger.warn(
      'Seed loader failed, starting with an empty database',
      error,
      stack,
    );
    await crashReporter.captureException(
      error,
      stackTrace: stack,
      context: 'bootstrap_seed',
    );
  }
}

/// MVP: автоматически покрывает вчерашний пропуск, если есть свободный freeze.
///
/// Условия: вчера нет ответов и вчера ещё не заморожено; серия, какой она была
/// к концу дня перед пропуском, уже заработала заморозку; эта заморозка ещё не
/// потрачена.
///
/// Почему считается серия «до пропуска», а не текущая: `ComputeStreak`
/// останавливается на первом пустом дне, поэтому после пропуска она всегда
/// даёт 1 (или 0) и никогда не покажет заработанный freeze — условие
/// «текущая серия длиннее нуля и есть запас» не сработало бы никогда.
///
/// Полная логика непрерывности и защита от эксплойта (ручное добавление
/// freeze) — Phase 5e (BL-50).
Future<void> _coverMissedDay(ProviderContainer container, Logger logger) async {
  final stats = container.read(statsRepositoryProvider);
  final frozen = container.read(frozenDaysRepositoryProvider);
  final yesterday = LocalDate.fromDateTime(
    container.read(clockProvider)().toLocal(),
  ).addDays(-1);

  try {
    final yesterdayStats = await stats.getForDate(yesterday);
    if ((yesterdayStats?.totalAnswers ?? 0) > 0) {
      return;
    }
    final frozenDates = await frozen.getAll();
    if (frozenDates.contains(yesterday)) {
      return;
    }

    // Серия на конец дня перед пропуском.
    final beforeGap = yesterday.addDays(-1);
    final streakBeforeGap = await ComputeStreak(
      stats: stats,
      frozen: frozen,
      clock: () => _localNoon(beforeGap),
    ).call();

    final earned = StreakRule.frozenEarnedFor(streakBeforeGap.count);
    if (streakBeforeGap.count > 0 && earned > frozenDates.length) {
      await container.read(markMissedDayProvider).call(yesterday);
    }
  } on Object catch (error, stack) {
    logger.warn('Missed-day freeze skipped', error, stack);
  }
}

/// Локальный полдень [date].
///
/// Полдень, а не полночь: `ComputeStreak` читает локальную дату момента, и
/// сдвиг на границе суток/DST не должен менять календарный день.
DateTime _localNoon(LocalDate date) {
  final utcMidnight = DateTime.fromMillisecondsSinceEpoch(
    date.daysSinceEpoch * Duration.millisecondsPerDay,
    isUtc: true,
  );
  return DateTime(utcMidnight.year, utcMidnight.month, utcMidnight.day, 12);
}

/// Выбирает отчётчик сбоев: Sentry при непустом DSN, иначе заглушку.
/// Сбой инициализации Sentry не должен ронять старт приложения: в этом случае
/// сбои уходят в лог, а приложение работает без crash reporting.
Future<CrashReporter> _initCrashReporter({
  required String? dsn,
  required Future<void> Function(String dsn)? init,
  required Logger logger,
}) async {
  if (dsn == null || dsn.isEmpty) {
    logger.warn('Sentry disabled (no DSN)');
    return const NoOpCrashReporter();
  }
  try {
    await (init ?? _defaultSentryInit)(dsn);
  } on Object catch (error, stack) {
    logger.error('Sentry init failed', error, stack);
    return const NoOpCrashReporter();
  }
  logger.info('Sentry enabled');
  return const SentryCrashReporter();
}

/// Настройки Sentry по умолчанию (ADR-016).
///
/// Performance-трейсы выключены: `tracesSampleRate` — это трейсы, а не доля
/// ошибок; доля ошибок задаётся `sampleRate`.
Future<void> _defaultSentryInit(String dsn) async {
  await SentryFlutter.init((options) {
    options
      ..dsn = dsn
      ..sendDefaultPii = false
      ..sampleRate = kReleaseMode ? 0.2 : 1.0
      ..tracesSampleRate = 0
      ..attachStacktrace = true;
  });
}

/// Точка входа приложения.
///
/// DSN приходит только через `--dart-define=SENTRY_DSN=...`; в коде, pubspec и
/// ассетах его быть не может.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const logger = DebugLogger();
  const dsn = String.fromEnvironment('SENTRY_DSN');
  final db = AppDatabase();
  final bootstrap = await bootstrapApp(
    db: db,
    bundle: rootBundle,
    logger: logger,
    sentryDsn: dsn.isEmpty ? null : dsn,
  );

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nextReviewLogIdProvider.overrideWithValue(bootstrap.idGenerator.next),
        loggerProvider.overrideWithValue(logger),
        crashReporterProvider.overrideWithValue(bootstrap.crashReporter),
      ],
      child: const EnglishEduApp(),
    ),
  );
}

/// Корневой виджет приложения.
class EnglishEduApp extends ConsumerWidget {
  /// Создаёт корневой виджет.
  const EnglishEduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'English Edu',
    theme: buildAppTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}
