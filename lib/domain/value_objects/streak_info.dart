import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:meta/meta.dart';

/// Computed streak: how many local days in a row had learning activity.
///
/// `@immutable` value object; it is derived from review logs, never stored.
@immutable
final class StreakInfo {
  /// Creates a streak; [count] must be non-negative.
  const StreakInfo({required this.count, this.lastActiveLocalDate})
    : assert(count >= 0, 'count must be >= 0');

  /// Length of the current streak, in local days.
  final int count;

  /// Last local day with activity, or null when there was none yet.
  final LocalDate? lastActiveLocalDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakInfo &&
          count == other.count &&
          lastActiveLocalDate == other.lastActiveLocalDate;

  @override
  int get hashCode => Object.hash(count, lastActiveLocalDate);

  @override
  String toString() =>
      'StreakInfo(count: $count, lastActive: $lastActiveLocalDate)';
}
