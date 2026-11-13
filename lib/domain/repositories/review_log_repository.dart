import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Append-only access to the review log.
///
/// [append] is the only operation the learning loop may use. [replaceAll]
/// существует исключительно для импорта и восстановления — обычный код
/// не должен его вызывать.
abstract interface class ReviewLogRepository {
  /// Appends [log]. Entries are never updated or deleted.
  Future<void> append(ReviewLog log);

  /// Returns entries whose word is [wordId], oldest first.
  Future<List<ReviewLog>> getByWordId(WordId wordId);

  /// Returns every entry.
  ///
  /// Used by export; ordering is implementation-defined.
  Future<List<ReviewLog>> getAll();

  /// Returns entries in the half-open range `[fromUtc, toUtc)`.
  ///
  /// Both bounds must be in UTC; implementations throw [ArgumentError] if they
  /// are not (release-safe, not an assert) because an abstract declaration
  /// cannot validate itself.
  Future<List<ReviewLog>> getByDateRange(DateTime fromUtc, DateTime toUtc);

  /// Атомарно заменяет весь журнал на [logs].
  ///
  /// Единственное исключение из append-only: только для импорта и
  /// восстановления. Обычный код вызывает только [append].
  Future<void> replaceAll(Iterable<ReviewLog> logs);

  /// Удаляет одну запись журнала.
  ///
  /// Исключение из append-only: только для `UndoLastReview` в активной
  /// сессии (ADR-010). Вне сессии записи не удаляются.
  Future<void> delete(ReviewLogId id);
}
