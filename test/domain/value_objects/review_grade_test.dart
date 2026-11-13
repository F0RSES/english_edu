import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewGrade', () {
    test('exposes the SM-2 quality of every grade', () {
      expect(ReviewGrade.again.quality, 0);
      expect(ReviewGrade.hard.quality, 3);
      expect(ReviewGrade.good.quality, 4);
      expect(ReviewGrade.easy.quality, 5);
    });

    test('treats only again as a failure', () {
      expect(ReviewGrade.again.isFailure, isTrue);
      expect(ReviewGrade.hard.isFailure, isFalse);
      expect(ReviewGrade.good.isFailure, isFalse);
      expect(ReviewGrade.easy.isFailure, isFalse);
    });

    test('declares grades in ascending quality order', () {
      expect(ReviewGrade.values, [
        ReviewGrade.again,
        ReviewGrade.hard,
        ReviewGrade.good,
        ReviewGrade.easy,
      ]);
    });

    test('keeps a stable name for serialisation', () {
      expect(ReviewGrade.values.map((grade) => grade.name).toList(), [
        'again',
        'hard',
        'good',
        'easy',
      ]);
    });
  });
}
