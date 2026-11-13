import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';

/// Собирает полный снимок состояния для бэкапа.
///
/// Читает всё содержимое через `getAll`, поэтому не зависит от перечисления
/// статусов или диапазонов дат: новые статусы и записи попадают в снимок
/// автоматически. Схема — [ExportPayload.currentSchemaVersion] (v2 включает
/// заморозки серии); формат JSON — ответственность data-слоя.
final class ExportProgress {
  /// Creates the use case.
  const ExportProgress({
    required SettingsRepository settings,
    required ProgressRepository progress,
    required ReviewLogRepository reviewLog,
    required StatsRepository stats,
    required WordRepository words,
    required FrozenDaysRepository frozen,
    required DateTime Function() clock,
  }) : _settings = settings,
       _progress = progress,
       _reviewLog = reviewLog,
       _stats = stats,
       _words = words,
       _frozen = frozen,
       _clock = clock;

  final SettingsRepository _settings;
  final ProgressRepository _progress;
  final ReviewLogRepository _reviewLog;
  final StatsRepository _stats;
  final WordRepository _words;
  final FrozenDaysRepository _frozen;
  final DateTime Function() _clock;

  /// Returns a snapshot of everything stored right now.
  Future<ExportPayload> call() async {
    return ExportPayload(
      schemaVersion: ExportPayload.currentSchemaVersion,
      exportedAt: _clock().toUtc(),
      settings: await _settings.get(),
      words: await _words.getAll(),
      progress: await _progress.getAll(),
      logs: await _reviewLog.getAll(),
      stats: await _stats.getAll(),
      frozenDays: await _frozen.getAll(),
    );
  }
}
