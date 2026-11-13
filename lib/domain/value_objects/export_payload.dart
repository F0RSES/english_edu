import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:meta/meta.dart';

/// Снимок полного состояния для бэкапа и восстановления.
///
/// Формат JSON — ответственность data-слоя (Phase 2). Схема — версия 1.
/// Валидация полей выполняется в `ImportProgress`, а не в конструкторе:
/// иначе невозможно построить заведомо некорректный payload для проверки.
@immutable
final class ExportPayload {
  /// Creates a snapshot with unmodifiable copies of every list.
  ExportPayload({
    required this.schemaVersion,
    required this.exportedAt,
    required this.settings,
    required List<Word> words,
    required List<WordProgress> progress,
    required List<ReviewLog> logs,
    required List<DailyStats> stats,
  })  : words = List.unmodifiable(words),
        progress = List.unmodifiable(progress),
        logs = List.unmodifiable(logs),
        stats = List.unmodifiable(stats);

  /// Version of the export schema; only 1 is supported.
  final int schemaVersion;

  /// Moment the snapshot was taken, UTC.
  final DateTime exportedAt;

  /// User settings at export time.
  final UserSettings settings;

  /// Vocabulary snapshot.
  final List<Word> words;

  /// Learning progress snapshot.
  final List<WordProgress> progress;

  /// Review log snapshot.
  final List<ReviewLog> logs;

  /// Per-day counters snapshot.
  final List<DailyStats> stats;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportPayload &&
          schemaVersion == other.schemaVersion &&
          exportedAt == other.exportedAt &&
          settings == other.settings &&
          _sameItems(words, other.words) &&
          _sameItems(progress, other.progress) &&
          _sameItems(logs, other.logs) &&
          _sameItems(stats, other.stats);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        exportedAt,
        settings,
        Object.hashAll(words),
        Object.hashAll(progress),
        Object.hashAll(logs),
        Object.hashAll(stats),
      );

  @override
  String toString() => 'ExportPayload(v$schemaVersion, '
      'at: ${exportedAt.toIso8601String()}, '
      'words: ${words.length}, progress: ${progress.length}, '
      'logs: ${logs.length}, stats: ${stats.length})';
}

bool _sameItems<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
