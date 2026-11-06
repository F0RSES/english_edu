import 'package:english_edu/domain/services/cloud_sync_service.dart';

/// Синхронизация без сети (ADR-022).
///
/// Фиксирует число вызовов, чтобы тест проверял нажатие, а не только текст.
final class FakeCloudSyncService implements CloudSyncService {
  /// Создаёт фейк с заданным отчётом или ошибкой.
  FakeCloudSyncService({this.report = SyncReport.empty, this.error});

  /// Отчёт, который вернёт `sync`.
  final SyncReport report;

  /// Ошибка, которую бросит `sync`; null — успех.
  final Exception? error;

  /// Сколько раз вызывали `sync`.
  int syncCalls = 0;

  @override
  Future<SyncReport> push() async => report;

  @override
  Future<SyncReport> pull() async => report;

  @override
  Future<SyncReport> sync() async {
    syncCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return report;
  }
}
