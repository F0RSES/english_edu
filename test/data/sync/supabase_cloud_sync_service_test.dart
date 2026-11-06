import 'package:english_edu/data/sync/remote_progress_row.dart';
import 'package:english_edu/data/sync/supabase_cloud_sync_service.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_progress_repository.dart';

/// Облачное хранилище в памяти: сеть в тестах не нужна.
final class _FakeRemoteStore implements RemoteProgressStore {
  _FakeRemoteStore([Iterable<RemoteProgressRow> seed = const []])
    : rows = [...seed];

  final List<RemoteProgressRow> rows;
  int upsertCalls = 0;

  @override
  Future<List<RemoteProgressRow>> fetchAll() async => [...rows];

  @override
  Future<void> upsertAll(List<RemoteProgressRow> payload) async {
    upsertCalls++;
    // Повторяет поведение SQL upsert: строка с тем же ключом заменяется,
    // остальные остаются.
    final byWordId = {for (final row in rows) row.wordId.value: row};
    for (final row in payload) {
      byWordId[row.wordId.value] = row;
    }
    rows
      ..clear()
      ..addAll(byWordId.values);
  }
}

final _firstSeen = DateTime.utc(2026);
final DateTime _reviewed = _firstSeen.add(const Duration(days: 4));
final DateTime _stale = _firstSeen.add(const Duration(days: 2));

WordProgress _progress({
  required int id,
  required DateTime lastReviewedAt,
  int repetitions = 3,
}) => WordProgress(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 2500,
    intervalDays: 4,
    repetitions: repetitions,
    lapses: 0,
    dueAt: lastReviewedAt.add(const Duration(days: 4)),
  ),
  status: WordStatus.learning,
  firstSeenAt: _firstSeen,
  lastReviewedAt: lastReviewedAt,
);

RemoteProgressRow _row({
  required int id,
  required DateTime lastReviewedAt,
  int repetitions = 3,
}) => RemoteProgressRow(
  wordId: WordId(id),
  cardState: CardState(
    easePermille: 2500,
    intervalDays: 4,
    repetitions: repetitions,
    lapses: 0,
    dueAt: lastReviewedAt.add(const Duration(days: 4)),
  ),
  status: WordStatus.learning,
  firstSeenAtUtc: _firstSeen,
  lastReviewedAtUtc: lastReviewedAt,
);

void main() {
  group('push', () {
    test('sends every local record to the remote store', () async {
      final local = FakeProgressRepository([
        _progress(id: 1, lastReviewedAt: _reviewed),
        _progress(id: 2, lastReviewedAt: _reviewed),
      ]);
      final remote = _FakeRemoteStore();
      final service = SupabaseCloudSyncService(local: local, remote: remote);

      final report = await service.push();

      expect(report.pushed, 2);
      expect(report.pulled, 0);
      expect(remote.upsertCalls, 1);
      expect(remote.rows.map((row) => row.wordId.value), [1, 2]);
    });

    test('skips the network call when there is nothing to send', () async {
      final remote = _FakeRemoteStore();
      final service = SupabaseCloudSyncService(
        local: FakeProgressRepository(),
        remote: remote,
      );

      final report = await service.push();

      expect(report.pushed, 0);
      expect(remote.upsertCalls, 0);
    });
  });

  group('pull', () {
    test('applies a remote row that is newer than the local one', () async {
      final local = FakeProgressRepository([
        _progress(id: 1, lastReviewedAt: _reviewed),
      ]);
      final service = SupabaseCloudSyncService(
        local: local,
        remote: _FakeRemoteStore([
          _row(
            id: 1,
            lastReviewedAt: _reviewed.add(const Duration(days: 1)),
            repetitions: 7,
          ),
        ]),
      );

      final report = await service.pull();

      expect(report.pulled, 1);
      expect(
        (await local.getByWordId(const WordId(1)))?.cardState.repetitions,
        7,
      );
    });

    test('keeps the local row when it is newer than the remote one', () async {
      final local = FakeProgressRepository([
        _progress(id: 1, lastReviewedAt: _reviewed, repetitions: 7),
      ]);
      final service = SupabaseCloudSyncService(
        local: local,
        remote: _FakeRemoteStore([_row(id: 1, lastReviewedAt: _stale)]),
      );

      final report = await service.pull();

      expect(report.pulled, 0);
      expect(
        (await local.getByWordId(const WordId(1)))?.cardState.repetitions,
        7,
      );
    });

    test('does not rewrite a row with an equal timestamp', () async {
      final local = FakeProgressRepository([
        _progress(id: 1, lastReviewedAt: _reviewed, repetitions: 7),
      ]);
      final service = SupabaseCloudSyncService(
        local: local,
        remote: _FakeRemoteStore([_row(id: 1, lastReviewedAt: _reviewed)]),
      );

      final report = await service.pull();

      expect(report.pulled, 0);
      expect(
        (await local.getByWordId(const WordId(1)))?.cardState.repetitions,
        7,
      );
    });

    test('adds a word that exists only in the cloud', () async {
      final local = FakeProgressRepository();
      final service = SupabaseCloudSyncService(
        local: local,
        remote: _FakeRemoteStore([_row(id: 5, lastReviewedAt: _reviewed)]),
      );

      final report = await service.pull();

      expect(report.pulled, 1);
      expect(await local.getByWordId(const WordId(5)), isNotNull);
    });
  });

  group('sync', () {
    test('combines push and pull counts', () async {
      final local = FakeProgressRepository([
        _progress(id: 1, lastReviewedAt: _reviewed),
      ]);
      final service = SupabaseCloudSyncService(
        local: local,
        remote: _FakeRemoteStore([_row(id: 2, lastReviewedAt: _reviewed)]),
      );

      final report = await service.sync();

      expect(report.pushed, 1);
      expect(report.pulled, 1);
    });
  });
}
