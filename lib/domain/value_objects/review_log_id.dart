import 'package:meta/meta.dart';

/// Stable identifier of a single review attempt in the log.
///
/// `@immutable` value object: wraps a non-negative index; equality and
/// ordering are defined by [value].
@immutable
final class ReviewLogId implements Comparable<ReviewLogId> {
  /// Creates an identifier from a non-negative [value].
  ///
  /// Fails with an [AssertionError] when [value] is negative.
  const ReviewLogId(this.value)
      : assert(value >= 0, 'review log id must be >= 0');

  /// Raw non-negative index behind this identifier.
  final int value;

  @override
  int compareTo(ReviewLogId other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReviewLogId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReviewLogId($value)';
}
