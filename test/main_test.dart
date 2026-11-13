import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:english_edu/core/crash_reporter.dart';
import 'package:english_edu/core/logger.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_frozen_days_repository.dart';
import 'package:english_edu/data/repositories/drift_review_log_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Отдаёт содержимое файла как ассет: в тестах нет Flutter asset bundle.
final class FileAssetBundle extends AssetBundle {
  FileAssetBundle(this.path);

  final String path;

  @override
  Future<ByteData> load(String key) async {
    final bytes = File(path).readAsBytesSync();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// Отдаёт заранее подготовленный JSON.
final class JsonAssetBundle extends AssetBundle {
  JsonAssetBundle(this.json);

  final String json;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
}

final now = DateTime.utc(2024, 5, 15, 12);

ReviewLog log(int id) => ReviewLog(
  id: ReviewLogId(id),
  wordId: const WordId(1),
  reviewedAt: now,
  grade: ReviewGrade.good,
  previousCardState: CardState.initial(now),
  newCardState: CardState.initial(now),
);

/// Дневные счётчики для проверки заморозки при старте.
Future<void> insertStats(AppDatabase db, LocalDate date) => db
    .into(db.dailyStatsTable)
    .insert(
      DailyStatsTableCompanion.insert(
        dateEpochDays: Value(date.daysSinceEpoch),
        newWordsStudied: const Value(1),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftWordRepository words;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    words = DriftWordRepository(db);
  });
  tearDown(() => db.close());

  test(
    'bootstrap seeds an empty database and continues ids after logs',
    () async {
      final logs = DriftReviewLogRepository(db);
      for (var id = 1; id <= 20; id++) {
        await logs.append(log(id));
      }

      final result = await bootstrapApp(
        db: db,
        logger: const DebugLogger(),
        bundle: FileAssetBundle('assets/seed/words_v1.json'),
        sentryDsn: null,
      );

      expect(await words.count(), 20);
      expect(result.idGenerator.next().value, 21);
    },
  );

  test('bootstrap survives a broken seed', () async {
    final result = await bootstrapApp(
      db: db,
      logger: const DebugLogger(),
      bundle: JsonAssetBundle('{"schemaVersion": 999}'),
      sentryDsn: null,
    );

    expect(await words.count(), 0);
    expect(result.idGenerator.next().value, 1);
  });

  test('bootstrap skips seeding when the database is not empty', () async {
    await words.upsert(
      const domain.Word(id: WordId(1), term: 'one', translation: 'один'),
    );

    await bootstrapApp(
      db: db,
      logger: const DebugLogger(),
      bundle: FileAssetBundle('assets/seed/words_v1.json'),
      sentryDsn: null,
    );

    expect(await words.count(), 1);
  });

  test('bootstrap without a DSN selects the no-op reporter', () async {
    final result = await bootstrapApp(
      db: db,
      logger: const DebugLogger(),
      bundle: FileAssetBundle('assets/seed/words_v1.json'),
      sentryDsn: null,
    );

    expect(result.crashReporter, isA<NoOpCrashReporter>());
  });

  test(
    'bootstrap with a DSN selects Sentry and passes the DSN to init',
    () async {
      String? received;
      final result = await bootstrapApp(
        db: db,
        logger: const DebugLogger(),
        bundle: FileAssetBundle('assets/seed/words_v1.json'),
        sentryDsn: 'https://key@example.invalid/1',
        sentryInit: (dsn) async {
          received = dsn;
        },
      );

      expect(received, 'https://key@example.invalid/1');
      expect(result.crashReporter, isA<SentryCrashReporter>());
    },
  );

  test(
    'bootstrap falls back to the no-op reporter when Sentry init fails',
    () async {
      final result = await bootstrapApp(
        db: db,
        logger: const DebugLogger(),
        bundle: FileAssetBundle('assets/seed/words_v1.json'),
        sentryDsn: 'https://key@example.invalid/1',
        sentryInit: (_) async => throw StateError('native init failed'),
      );

      expect(result.crashReporter, isA<NoOpCrashReporter>());
    },
  );

  test(
    'bootstrap freezes a missed yesterday earned by the pre-gap streak',
    () async {
      final today = LocalDate.fromDateTime(DateTime.now());
      // Восемь дней подряд, заканчивая позавчерашним: к концу такой серии
      // заработана одна заморозка, а вчера остался пустым.
      for (var offset = 2; offset <= 9; offset++) {
        await insertStats(db, today.addDays(-offset));
      }

      await bootstrapApp(
        db: db,
        logger: const DebugLogger(),
        bundle: FileAssetBundle('assets/seed/words_v1.json'),
        sentryDsn: null,
      );

      final frozen = await db.select(db.frozenDays).get();
      expect(frozen, hasLength(1));
      expect(frozen.single.dateEpochDays, today.addDays(-1).daysSinceEpoch);
      expect(frozen.single.reason, 'missedDay');
    },
  );

  test('bootstrap leaves yesterday alone when no freeze was earned', () async {
    final today = LocalDate.fromDateTime(DateTime.now());
    for (var offset = 2; offset <= 6; offset++) {
      await insertStats(db, today.addDays(-offset));
    }

    await bootstrapApp(
      db: db,
      logger: const DebugLogger(),
      bundle: FileAssetBundle('assets/seed/words_v1.json'),
      sentryDsn: null,
    );

    expect(await db.select(db.frozenDays).get(), isEmpty);
  });

  test(
    'bootstrap does not freeze again when the previous freeze is spent',
    () async {
      final today = LocalDate.fromDateTime(DateTime.now());
      for (var offset = 2; offset <= 9; offset++) {
        await insertStats(db, today.addDays(-offset));
      }
      final alreadyFrozen = today.addDays(-30);
      await DriftFrozenDaysRepository(
        db,
        clock: DateTime.now,
      ).add(alreadyFrozen, reason: 'missedDay');

      await bootstrapApp(
        db: db,
        logger: const DebugLogger(),
        bundle: FileAssetBundle('assets/seed/words_v1.json'),
        sentryDsn: null,
      );

      final frozen = await db.select(db.frozenDays).get();
      expect(frozen, hasLength(1));
      expect(frozen.single.dateEpochDays, alreadyFrozen.daysSinceEpoch);
    },
  );
}
