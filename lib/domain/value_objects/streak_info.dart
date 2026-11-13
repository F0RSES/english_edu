import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:meta/meta.dart';

/// Computed streak: how many local days in a row had learning activity.
///
/// `@immutable` value object; it is derived from review logs, never stored.
/// Заморозки (`frozenAvailable`, `frozenDates`) приходят из `FrozenDays`
/// и участвуют в равенстве: два `StreakInfo` с разным балансом не равны.
@immutable
final class StreakInfo {
  /// Creates a streak; [count] and [frozenAvailable] must be non-negative.
  const StreakInfo({
    required this.count,
    this.lastActiveLocalDate,
    this.frozenAvailable = 0,
    this.frozenDates = const <LocalDate>{},
  }) : assert(count >= 0, 'count must be >= 0'),
       assert(frozenAvailable >= 0, 'frozenAvailable must be >= 0');

  /// Length of the current streak, in local days.
  final int count;

  /// Last local day with activity, or null when there was none yet.
  final LocalDate? lastActiveLocalDate;

  /// Сколько заморозок можно потратить прямо сейчас.
  ///
  /// Заработано по вехам (`StreakRule.frozenEarnedFor`) минус израсходовано.
  final int frozenAvailable;

  /// Даты, уже покрытые заморозкой.
  final Set<LocalDate> frozenDates;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakInfo &&
          count == other.count &&
          lastActiveLocalDate == other.lastActiveLocalDate &&
          frozenAvailable == other.frozenAvailable &&
          _sameDates(frozenDates, other.frozenDates);

  @override
  int get hashCode => Object.hash(
    count,
    lastActiveLocalDate,
    frozenAvailable,
    // Порядок не важен, поэтому не Object.hashAll: множества равны независимо
    // от порядка вставки.
    Object.hashAllUnordered(frozenDates),
  );

  @override
  String toString() =>
      'StreakInfo(count: $count, lastActive: $lastActiveLocalDate)';

  /// Сравнивает множества без `setEquals` из Flutter: domain — pure Dart.
  static bool _sameDates(Set<LocalDate> a, Set<LocalDate> b) =>
      a.length == b.length && a.containsAll(b);
}
