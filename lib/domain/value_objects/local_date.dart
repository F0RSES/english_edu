import 'package:meta/meta.dart';

/// Calendar day without time and without a time zone.
///
/// `@immutable` value object stored as a count of days since 1970-01-01, so
/// the value is stable across time zones and daylight saving changes.
@immutable
final class LocalDate implements Comparable<LocalDate> {
  /// Creates a date from [daysSinceEpoch]; negative values are before 1970.
  const LocalDate(this.daysSinceEpoch);

  /// Returns the calendar day of [now], or of the current instant.
  ///
  /// [now] is used as provided: year, month and day are read from it as
  /// written, so the caller owns the time zone choice. Called without an
  /// argument it yields the local day, because [DateTime.now] is local.
  factory LocalDate.today({DateTime? now}) =>
      LocalDate.fromDateTime(now ?? DateTime.now());

  /// Extracts the calendar day from the year, month and day of [dt].
  ///
  /// Components are taken exactly as written on [dt], whatever its zone is:
  /// a UTC instant and the same wall-clock local time give the same date.
  factory LocalDate.fromDateTime(DateTime dt) {
    final utcMidnight = DateTime.utc(dt.year, dt.month, dt.day);
    return LocalDate(
      utcMidnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
    );
  }

  /// Number of days from 1970-01-01; negative before the epoch.
  final int daysSinceEpoch;

  /// Returns this date shifted by [days].
  ///
  /// Month and year boundaries are handled by the epoch arithmetic itself.
  LocalDate addDays(int days) => LocalDate(daysSinceEpoch + days);

  @override
  int compareTo(LocalDate other) =>
      daysSinceEpoch.compareTo(other.daysSinceEpoch);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDate && daysSinceEpoch == other.daysSinceEpoch;

  @override
  int get hashCode => daysSinceEpoch.hashCode;

  @override
  String toString() {
    final moment = DateTime.fromMillisecondsSinceEpoch(
      daysSinceEpoch * Duration.millisecondsPerDay,
      isUtc: true,
    );
    final year = moment.year.toString().padLeft(4, '0');
    final month = moment.month.toString().padLeft(2, '0');
    final day = moment.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
