import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/export_progress.dart';
import 'package:english_edu/domain/usecases/import_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

import 'fakes/fake_frozen_days_repository.dart';
import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_review_log_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_stats_repository.dart';
import 'fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);
final today = LocalDate.fromDateTime(now.toLocal());

Word word(int id, {String? category, CefrLevel level = CefrLevel.a1}) => Word(
  id: WordId(id),
  term: 'term$id',
  translation: 'перевод$id',
  category: category,
  level: level,
);

WordProgress progressOf(int id) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 2500,
    intervalDays: 1,
    repetitions: 1,
    lapses: 0,
    dueAt: now,
  ),
  status: WordStatus.learning,
  firstSeenAt: now.subtract(const Duration(days: 5)),
);

final class Store {
  Store({
    List<Word> seedWords = const [],
    List<WordProgress> seedProgress = const [],
    List<ReviewLog> seedLogs = const [],
    List<DailyStats> seedStats = const [],
    UserSettings? settings,
    Iterable<LocalDate> seedFrozen = const [],
  }) : words = FakeWordRepository(seedWords),
       progress = FakeProgressRepository(seedProgress),
       logs = FakeReviewLogRepository(seedLogs),
       stats = FakeStatsRepository(seedStats),
       frozen = FakeFrozenDaysRepository(seedFrozen),
       settings = FakeSettingsRepository(settings);

  final FakeWordRepository words;
  final FakeProgressRepository progress;
  final FakeReviewLogRepository logs;
  final FakeStatsRepository stats;
  final FakeFrozenDaysRepository frozen;
  final FakeSettingsRepository settings;

  ImportProgress get importUseCase => ImportProgress(
    words: words,
    progress: progress,
    reviewLog: logs,
    settings: settings,
    stats: stats,
    frozen: frozen,
  );

  ExportProgress get exportUseCase => ExportProgress(
    settings: settings,
    progress: progress,
    reviewLog: logs,
    stats: stats,
    words: words,
    frozen: frozen,
    clock: () => now,
  );
}

ExportPayload payloadOf({
  int schemaVersion = 1,
  List<Word> words = const [],
  List<WordProgress> progress = const [],
  List<ReviewLog> logs = const [],
  List<DailyStats> stats = const [],
  Set<LocalDate> frozenDays = const {},
  DateTime? exportedAt,
}) => ExportPayload(
  schemaVersion: schemaVersion,
  exportedAt: exportedAt ?? now,
  settings: UserSettings.defaults(),
  words: words,
  progress: progress,
  logs: logs,
  stats: stats,
  frozenDays: frozenDays,
);

void main() {
  group('ImportProgress', () {
    test('rejects an unsupported schema version', () async {
      await expectLater(
        Store().importUseCase(payloadOf(schemaVersion: 7)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('restores frozen days from a v2 payload', () async {
      final store = Store();

      await store.importUseCase(
        payloadOf(schemaVersion: 2, frozenDays: {const LocalDate(19723)}),
      );

      expect(await store.frozen.getAll(), {const LocalDate(19723)});
    });

    test('leaves frozen days empty for a v1 payload', () async {
      final store = Store(seedFrozen: const [LocalDate(19723)]);

      await store.importUseCase(payloadOf());

      expect(await store.frozen.getAll(), isEmpty);
    });

    test('round-trips frozen days through export and import', () async {
      final source = Store(
        seedFrozen: const [LocalDate(19723), LocalDate(19724)],
      );
      final target = Store();

      await target.importUseCase(await source.exportUseCase());

      expect(await target.frozen.getAll(), await source.frozen.getAll());
    });

    test('restores categories from a v3 payload', () async {
      final store = Store();

      await store.importUseCase(
        payloadOf(schemaVersion: 3, words: [word(1, category: 'Быт')]),
      );

      final imported = await store.words.getById(const WordId(1));
      expect(imported!.category, 'Быт');
    });

    test('import v4 restores cefr levels', () async {
      final store = Store();

      await store.importUseCase(
        payloadOf(
          schemaVersion: 4,
          words: [
            word(1, level: CefrLevel.a2),
            word(2, level: CefrLevel.c2),
          ],
        ),
      );

      final restored = await store.words.getAll();
      expect(
        [for (final item in restored) item.level],
        [CefrLevel.a2, CefrLevel.c2],
      );
    });

    test('rejects a non-UTC exportedAt', () async {
      await expectLater(
        Store().importUseCase(payloadOf(exportedAt: DateTime(2024, 5, 15))),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('writes an empty payload and leaves stores empty', () async {
      final store = Store(seedWords: [word(9)], seedLogs: []);
      await store.importUseCase(payloadOf());

      expect(await store.words.getAll(), isEmpty);
      expect(await store.progress.getByStatus(WordStatus.learning), isEmpty);
      expect(await store.stats.getRange(const LocalDate(0), today), isEmpty);
    });

    test('replaces existing data instead of merging', () async {
      final store = Store(seedWords: [word(9)]);
      await store.importUseCase(payloadOf(words: [word(1)]));

      final all = await store.words.getAll();
      expect(all, [word(1)]);
    });

    test('round-trips through export', () async {
      final source = Store(seedWords: [word(1)]);
      final payload = await source.exportUseCase();

      final target = Store();
      await target.importUseCase(payload);
      final restored = await target.exportUseCase();

      expect(restored, equals(payload));
    });
  });
}
