import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
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
/// Drift). Use case делает шесть последовательных шагов: settings → words →
/// progress → logs → stats → frozen.
///
/// Схема v1 импортируется с пустыми заморозками (обратная совместимость);
/// поддерживаются версии 1 и [ExportPayload.currentSchemaVersion].
final class ImportProgress {
  /// Creates the use case.
  const ImportProgress({
    required WordRepository words,
    required ProgressRepository progress,
    required ReviewLogRepository reviewLog,
    required SettingsRepository settings,
    required StatsRepository stats,
    required FrozenDaysRepository frozen,
  }) : _words = words,
       _progress = progress,
       _reviewLog = reviewLog,
       _settings = settings,
       _stats = stats,
       _frozen = frozen;

  final WordRepository _words;
  final ProgressRepository _progress;
  final ReviewLogRepository _reviewLog;
  final SettingsRepository _settings;
  final StatsRepository _stats;
  final FrozenDaysRepository _frozen;

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
    await _frozen.replaceAll(payload.frozenDays);
  }

  void _validate(ExportPayload payload) {
    final version = payload.schemaVersion;
    final isSupported =
        version >= 1 && version <= ExportPayload.currentSchemaVersion;
    if (!isSupported) {
      throw ArgumentError.value(
        version,
        'schemaVersion',
        'supported versions: 1..${ExportPayload.currentSchemaVersion}',
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
