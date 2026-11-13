import 'package:english_edu/domain/value_objects/review_grade.dart';

/// Правила начисления XP и зачёта ответа как верного.
///
/// Централизовано: и `RecordReview`, и `UndoLastReview` обязаны использовать
/// эти функции, чтобы UI и откат не расходились с записью.
abstract final class XpRules {
  /// XP за ответ с оценкой [grade].
  static int forGrade(ReviewGrade grade) => switch (grade) {
    ReviewGrade.again => 0,
    ReviewGrade.hard => 5,
    ReviewGrade.good => 10,
    ReviewGrade.easy => 15,
  };

  /// Считается ли ответ верным.
  static bool isCorrect(ReviewGrade grade) => grade != ReviewGrade.again;
}
