import 'package:meta/meta.dart';

/// Stable identifier of a word in the seeded vocabulary.
///
/// `@immutable` value object: wraps a non-negative index; equality and
/// ordering are defined by [value].
@immutable
final class WordId implements Comparable<WordId> {
  /// Creates an identifier from a non-negative [value].
  ///
  /// Fails with an [AssertionError] when [value] is negative.
  const WordId(this.value) : assert(value >= 0, 'word id must be >= 0');

  /// Raw non-negative index behind this identifier.
  final int value;

  @override
  int compareTo(WordId other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WordId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'WordId($value)';
}
