import 'package:english_edu/data/sync/remote_progress_row.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/services/cloud_sync_service.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Синхронизация прогресса поверх [RemoteProgressStore] (ADR-022).
///
/// Слияние детерминировано и не зависит от сети: побеждает строка с более
/// поздним `updatedAtUtc`, при равенстве — локальная. Равные штампы не
/// перезаписываются, чтобы повторный pull не порождал записи в БД.
final class SupabaseCloudSyncService implements CloudSyncService {
  /// Создаёт сервис над локальным репозиторием и облачным хранилищем.
  const SupabaseCloudSyncService({
    required ProgressRepository local,
    required RemoteProgressStore remote,
  }) : _local = local,
       _remote = remote;

  final ProgressRepository _local;
  final RemoteProgressStore _remote;

  @override
  Future<SyncReport> push() async {
    final localRows = await _local.getAll();
    if (localRows.isEmpty) {
      return SyncReport.empty;
    }
    await _remote.upsertAll([
      for (final progress in localRows) RemoteProgressRow.fromDomain(progress),
    ]);
    return SyncReport(pushed: localRows.length, pulled: 0);
  }

  @override
  Future<SyncReport> pull() async {
    final remoteRows = await _remote.fetchAll();
    if (remoteRows.isEmpty) {
      return SyncReport.empty;
    }
    final localById = <WordId, WordProgress>{
      for (final progress in await _local.getAll()) progress.wordId: progress,
    };
    var applied = 0;
    for (final row in remoteRows) {
      final local = localById[row.wordId];
      if (local == null || _isNewer(row, local)) {
        await _local.upsert(row.toDomain());
        applied++;
      }
    }
    return SyncReport(pushed: 0, pulled: applied);
  }

  @override
  Future<SyncReport> sync() async => await push() + await pull();

  static bool _isNewer(RemoteProgressRow row, WordProgress local) {
    final localStamp = local.lastReviewedAt ?? local.firstSeenAt;
    return row.updatedAtUtc.isAfter(localStamp);
  }
}
