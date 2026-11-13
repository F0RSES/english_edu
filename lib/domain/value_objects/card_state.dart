import 'package:meta/meta.dart';

/// Scheduling state of a single word, independent of storage.
///
/// `@immutable` value object; [dueAt] is always stored in UTC.
@immutable
final class CardState {
  /// Creates a state and normalises [dueAt] to UTC.
  ///
  /// [easePermille] is the SM-2 ease factor scaled by 1000, so 2500 means
  /// 2.5. Integer scaling keeps equality deterministic across platforms.
  CardState({
    required this.easePermille,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required DateTime dueAt,
  }) : dueAt = dueAt.toUtc(),
       assert(easePermille >= 1300, 'easePermille must be >= 1300'),
       assert(intervalDays >= 0, 'intervalDays must be >= 0'),
       assert(repetitions >= 0, 'repetitions must be >= 0'),
       assert(lapses >= 0, 'lapses must be >= 0');

  /// Fresh card whose first answer is expected at [dueAt].
  factory CardState.initial(DateTime dueAt) => CardState(
    easePermille: 2500,
    intervalDays: 0,
    repetitions: 0,
    lapses: 0,
    dueAt: dueAt,
  );

  /// Ease factor scaled by 1000; 1300 stands for 1.3.
  final int easePermille;

  /// Current interval between reviews, in whole days.
  final int intervalDays;

  /// Successful repetitions in a row.
  final int repetitions;

  /// Number of failed recalls.
  final int lapses;

  /// Moment when the card becomes due again, always in UTC.
  final DateTime dueAt;

  /// Ease factor as a ratio, for display and for SM-2 math.
  double get ease => easePermille / 1000.0;

  /// Returns a copy with the given fields replaced.
  CardState copyWith({
    int? easePermille,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
  }) => CardState(
    easePermille: easePermille ?? this.easePermille,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    dueAt: dueAt ?? this.dueAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardState &&
          easePermille == other.easePermille &&
          intervalDays == other.intervalDays &&
          repetitions == other.repetitions &&
          lapses == other.lapses &&
          dueAt.microsecondsSinceEpoch == other.dueAt.microsecondsSinceEpoch;

  @override
  int get hashCode => Object.hash(
    easePermille,
    intervalDays,
    repetitions,
    lapses,
    dueAt.microsecondsSinceEpoch,
  );

  @override
  String toString() =>
      'CardState(ease: $ease, '
      'interval: ${intervalDays}d, reps: $repetitions, lapses: $lapses, '
      'dueAt: ${dueAt.toIso8601String()})';
}
