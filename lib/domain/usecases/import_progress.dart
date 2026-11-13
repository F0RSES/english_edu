import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';

/// Восстанавливает состояние из снимка.
///
/// MVP: REPLACE, не merge — содержимое каждого репозитория заменяется через
/// `replaceAll`. Merge — Phase 5 с отдельным ADR.
///
/// Атомарность per-repo; межрепозиторная атомарность — Phase 2 (транзакция
/// Drift). Use case делает пять последовательных шагов: settings → words →
/// progress → logs → stats.
final class ImportProgress {
  /// Creates the use case.
  const ImportProgress({
    required WordRepository words,
    required ProgressRepository progress,
    required ReviewLogRepository reviewLog,
    required SettingsRepository settings,
    required StatsRepository stats,
  }) : _words = words,
       _progress = progress,
       _reviewLog = reviewLog,
       _settings = settings,
       _stats = stats;

  final WordRepository _words;
  final ProgressRepository _progress;
  final ReviewLogRepository _reviewLog;
  final SettingsRepository _settings;
  final StatsRepository _stats;

  /// Replaces all stored data with [payload].
  ///
  /// Throws [ArgumentError] when the schema version is unsupported or when
  /// [ExportPayload.exportedAt] is not in UTC.
  Future<void> call(ExportPayload payload) async {
    _validate(payload);

    await _settings.save(payload.settings);
    await _words.replaceAll(payload.words);
    await _progress.replaceAll(payload.progress);
    await _reviewLog.replaceAll(payload.logs);
    await _stats.replaceAll(payload.stats);
  }

  void _validate(ExportPayload payload) {
    if (payload.schemaVersion != 1) {
      throw ArgumentError.value(
        payload.schemaVersion,
        'schemaVersion',
        'only schema version 1 is supported',
      );
    }
    if (!payload.exportedAt.isUtc) {
      throw ArgumentError.value(
        payload.exportedAt,
        'exportedAt',
        'exportedAt must be UTC',
      );
    }
  }
}
