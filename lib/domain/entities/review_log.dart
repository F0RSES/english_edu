import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Immutable record of one answer. The log is append-only.
///
/// Throws [ArgumentError] for a non-UTC timestamp.
@immutable
final class ReviewLog {
  /// Creates a log entry; [reviewedAt] must be in UTC.
  ///
  /// Not `const`: the timestamp is validated at runtime, because an assert is
  /// stripped in release builds.
  ReviewLog({
    required this.id,
    required this.wordId,
    required DateTime reviewedAt,
    required this.grade,
    required this.previousCardState,
    required this.newCardState,
  }) : reviewedAt = _requireUtc(reviewedAt, 'reviewedAt');

  /// Identifier of this entry.
  final ReviewLogId id;

  /// Word that was answered.
  final WordId wordId;

  /// Moment of the answer, in UTC.
  final DateTime reviewedAt;

  /// Grade reported by the learner.
  final ReviewGrade grade;

  /// Card state before the answer.
  final CardState previousCardState;

  /// Card state produced by the answer.
  final CardState newCardState;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewLog &&
          id == other.id &&
          wordId == other.wordId &&
          reviewedAt == other.reviewedAt &&
          grade == other.grade &&
          previousCardState == other.previousCardState &&
          newCardState == other.newCardState;

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    reviewedAt,
    grade,
    previousCardState,
    newCardState,
  );

  @override
  String toString() =>
      'ReviewLog(${id.value}, word=${wordId.value}, '
      'grade=$grade, at=${reviewedAt.toIso8601String()})';
}
