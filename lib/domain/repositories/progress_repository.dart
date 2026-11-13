import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Read and write access to per-word learning progress.
abstract interface class ProgressRepository {
  /// Returns progress for [wordId], or null when the word was never shown.
  Future<WordProgress?> getByWordId(WordId wordId);

  /// Returns progress records whose word is currently in [status].
  Future<List<WordProgress>> getByStatus(WordStatus status);

  /// Returns every progress record.
  ///
  /// Used by export; ordering is implementation-defined.
  Future<List<WordProgress>> getAll();

  /// Returns cards whose due date is at or before [utcInstant].
  ///
  /// Results are ordered by due date, earliest first. [utcInstant] must be
  /// in UTC; implementations throw [ArgumentError] if it is not (release-safe,
  /// not an assert) because an abstract declaration cannot validate itself.
  Future<List<WordProgress>> getDueBefore(DateTime utcInstant);

  /// Inserts [progress] or replaces the record for the same word.
  Future<void> upsert(WordProgress progress);

  /// Атомарно заменяет все записи прогресса.
  ///
  /// Для импорта и восстановления.
  Future<void> replaceAll(Iterable<WordProgress> items);
}
