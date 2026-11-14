import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
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
    Set<LocalDate> frozenDays = const <LocalDate>{},
  }) : words = List.unmodifiable(words),
       progress = List.unmodifiable(progress),
       logs = List.unmodifiable(logs),
       stats = List.unmodifiable(stats),
       frozenDays = Set.unmodifiable(frozenDays);

  /// Версия схемы, которую пишет приложение.
  ///
  /// v2: `+ frozenDays`; v3: `+ Word.category`. Старшие снимки совместимы:
  /// отсутствующее поле приходит пустым (`category = null`), версии выше
  /// текущей отклоняются импортом как неизвестный более новый формат.
  static const int currentSchemaVersion = 3;

  /// Version of the export schema; 1 and 2 are supported on import.
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

  /// Замороженные дни серии (ADR-015); в v1 отсутствуют и приходят пустыми.
  final Set<LocalDate> frozenDays;

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
          _sameItems(stats, other.stats) &&
          _sameDates(frozenDays, other.frozenDays);

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    exportedAt,
    settings,
    Object.hashAll(words),
    Object.hashAll(progress),
    Object.hashAll(logs),
    Object.hashAll(stats),
    // Порядок вставки не важен: множества равны независимо от него.
    Object.hashAllUnordered(frozenDays),
  );

  @override
  String toString() =>
      'ExportPayload(v$schemaVersion, '
      'at: ${exportedAt.toIso8601String()}, '
      'words: ${words.length}, progress: ${progress.length}, '
      'logs: ${logs.length}, stats: ${stats.length}, '
      'frozen: ${frozenDays.length})';

  /// Сравнивает множества без `setEquals` из Flutter: domain — pure Dart.
  static bool _sameDates(Set<LocalDate> a, Set<LocalDate> b) =>
      a.length == b.length && a.containsAll(b);
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
