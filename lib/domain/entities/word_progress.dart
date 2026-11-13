import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:meta/meta.dart';

/// Marker telling "absent" apart from an explicit null in `copyWith`.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

DateTime? _requireUtcOrNull(DateTime? value, String name) =>
    value == null ? null : _requireUtc(value, name);

/// Learning state of a single word: its card, status and timestamps.
///
/// Throws [ArgumentError] for non-UTC timestamps.
@immutable
final class WordProgress {
  /// Creates a progress record; both timestamps must be in UTC.
  ///
  /// Not `const`: timestamps are validated at runtime, because an assert is
  /// stripped in release builds.
  WordProgress({
    required this.wordId,
    required this.cardState,
    required this.status,
    required DateTime firstSeenAt,
    DateTime? lastReviewedAt,
  })  : firstSeenAt = _requireUtc(firstSeenAt, 'firstSeenAt'),
        lastReviewedAt = _requireUtcOrNull(lastReviewedAt, 'lastReviewedAt');

  /// Creates a record for a word that has never been answered.
  factory WordProgress.newWord({
    required WordId wordId,
    required DateTime now,
  }) =>
      WordProgress(
        wordId: wordId,
        cardState: CardState.initial(now),
        status: WordStatus.newWord,
        firstSeenAt: now.toUtc(),
      );

  /// Identifier of the word this record belongs to.
  final WordId wordId;

  /// Scheduling state of the word.
  final CardState cardState;

  /// Current learning status.
  final WordStatus status;

  /// Moment the word was shown for the first time, in UTC.
  final DateTime firstSeenAt;

  /// Moment of the last answer in UTC, or null when never answered.
  final DateTime? lastReviewedAt;

  /// Returns a copy with the given fields replaced.
  ///
  /// [lastReviewedAt] is cleared by passing null explicitly.
  WordProgress copyWith({
    WordId? wordId,
    CardState? cardState,
    WordStatus? status,
    DateTime? firstSeenAt,
    Object? lastReviewedAt = _unset,
  }) =>
      WordProgress(
        wordId: wordId ?? this.wordId,
        cardState: cardState ?? this.cardState,
        status: status ?? this.status,
        firstSeenAt: firstSeenAt ?? this.firstSeenAt,
        lastReviewedAt: identical(lastReviewedAt, _unset)
            ? this.lastReviewedAt
            : lastReviewedAt as DateTime?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordProgress &&
          wordId == other.wordId &&
          cardState == other.cardState &&
          status == other.status &&
          firstSeenAt == other.firstSeenAt &&
          lastReviewedAt == other.lastReviewedAt;

  @override
  int get hashCode =>
      Object.hash(wordId, cardState, status, firstSeenAt, lastReviewedAt);

  @override
  String toString() => 'WordProgress(word: ${wordId.value}, '
      'status: $status, card: $cardState, lastReviewed: $lastReviewedAt)';
}
