import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';

/// Stub SRS calculator with predictable output for use-case tests.
///
/// `again` resets repetitions and increases lapses; every other grade adds
/// [repetitionsDelta] to the current count. `dueAt` is always `now + 1 day`.
final class FakeSrsCalculator implements SrsCalculator {
  /// Creates a stub; [repetitionsDelta] is added for a successful answer.
  const FakeSrsCalculator({this.repetitionsDelta = 1});

  /// Repetitions added by a successful answer.
  final int repetitionsDelta;

  @override
  CardState apply(CardState current, ReviewGrade grade, DateTime now) {
    final failed = grade == ReviewGrade.again;
    return current.copyWith(
      repetitions: failed ? 0 : current.repetitions + repetitionsDelta,
      lapses: failed ? current.lapses + 1 : current.lapses,
      intervalDays: current.intervalDays + 1,
      dueAt: now.add(const Duration(days: 1)),
    );
  }
}
