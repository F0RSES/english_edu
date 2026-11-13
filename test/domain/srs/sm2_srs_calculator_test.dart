import 'package:english_edu/domain/srs/sm2_srs_calculator.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);
const srs = Sm2SrsCalculator();

CardState card({
  int ease = 2500,
  int interval = 0,
  int reps = 0,
  int lapses = 0,
}) => CardState(
  easePermille: ease,
  intervalDays: interval,
  repetitions: reps,
  lapses: lapses,
  dueAt: now,
);

void main() {
  group('Sm2SrsCalculator', () {
    test('first good answer schedules tomorrow and keeps ease', () {
      final next = srs.apply(card(), ReviewGrade.good, now);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.easePermille, 2500);
      expect(next.lapses, 0);
      expect(next.dueAt, now.add(const Duration(days: 1)));
    });

    test('first easy answer raises ease by 100', () {
      final next = srs.apply(card(), ReviewGrade.easy, now);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.easePermille, 2600);
    });

    test('first hard answer lowers ease by 140', () {
      final next = srs.apply(card(), ReviewGrade.hard, now);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.easePermille, 2360);
    });

    test('first again resets repetitions and counts a lapse', () {
      final next = srs.apply(card(), ReviewGrade.again, now);
      expect(next.repetitions, 0);
      expect(next.intervalDays, 1);
      expect(next.easePermille, 1700);
      expect(next.lapses, 1);
      expect(next.dueAt, now.add(const Duration(days: 1)));
    });

    test('second good answer moves to six days', () {
      final next = srs.apply(card(reps: 1, interval: 1), ReviewGrade.good, now);
      expect(next.repetitions, 2);
      expect(next.intervalDays, 6);
      expect(next.easePermille, 2500);
    });

    test('third good answer scales the interval by ease', () {
      final next = srs.apply(card(reps: 2, interval: 6), ReviewGrade.good, now);
      expect(next.repetitions, 3);
      expect(next.intervalDays, 15);
      expect(next.easePermille, 2500);
    });

    test('third easy answer scales by the raised ease', () {
      final next = srs.apply(card(reps: 2, interval: 6), ReviewGrade.easy, now);
      expect(next.repetitions, 3);
      expect(next.easePermille, 2600);
      expect(next.intervalDays, 16);
    });

    test('third hard answer scales by the lowered ease', () {
      final next = srs.apply(card(reps: 2, interval: 6), ReviewGrade.hard, now);
      expect(next.repetitions, 3);
      expect(next.easePermille, 2360);
      expect(next.intervalDays, 14);
    });

    test('again after a long streak resets and increases lapses', () {
      final next = srs.apply(
        card(reps: 5, interval: 60, lapses: 2),
        ReviewGrade.again,
        now,
      );
      expect(next.repetitions, 0);
      expect(next.intervalDays, 1);
      expect(next.lapses, 3);
      expect(next.easePermille, 1700);
    });

    test('ease never drops below 1300 on again', () {
      final next = srs.apply(card(ease: 1300), ReviewGrade.again, now);
      expect(next.easePermille, 1300);
    });

    test('ease never drops below 1300 on hard', () {
      final next = srs.apply(card(ease: 1300), ReviewGrade.hard, now);
      expect(next.easePermille, 1300);
    });

    test('repeated failures keep ease at the floor', () {
      var state = card(ease: 1500);
      for (var i = 0; i < 5; i++) {
        state = srs.apply(state, ReviewGrade.again, now);
      }
      expect(state.easePermille, 1300);
      expect(state.repetitions, 0);
      expect(state.lapses, 5);
    });

    test('dueAt is now plus the interval for every grade', () {
      final base = card(reps: 2, interval: 6);
      for (final grade in ReviewGrade.values) {
        final next = srs.apply(base, grade, now);
        expect(
          next.dueAt,
          now.add(Duration(days: next.intervalDays)),
          reason: '$grade',
        );
      }
    });

    test('rejects a non-UTC now', () {
      expect(
        () => srs.apply(card(), ReviewGrade.good, DateTime(2024, 5, 15, 12)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('is deterministic for the same input', () {
      final base = card(reps: 3, interval: 20);
      expect(
        srs.apply(base, ReviewGrade.hard, now),
        equals(srs.apply(base, ReviewGrade.hard, now)),
      );
    });

    test(
      'rounds the scaled interval with Dart round (half away from zero)',
      () {
        final next = srs.apply(
          card(reps: 2, interval: 7),
          ReviewGrade.good,
          now,
        );
        // 7 * 2.5 = 17.5 → 18
        expect(next.intervalDays, 18);
      },
    );
  });
}
