import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:test/test.dart';

void main() {
  group('StreakInfo', () {
    test('keeps lastActiveLocalDate null by default', () {
      const info = StreakInfo(count: 0);
      expect(info.count, 0);
      expect(info.lastActiveLocalDate, isNull);
    });

    test('stores the given count and last active date', () {
      const info = StreakInfo(count: 3, lastActiveLocalDate: LocalDate(19723));
      expect(info.count, 3);
      expect(info.lastActiveLocalDate, const LocalDate(19723));
    });

    test('rejects a negative count', () {
      expect(() => StreakInfo(count: -1), throwsA(isA<AssertionError>()));
    });

    test('is equal and has the same hash for equal fields', () {
      const a = StreakInfo(count: 2, lastActiveLocalDate: LocalDate(19723));
      const b = StreakInfo(count: 2, lastActiveLocalDate: LocalDate(19723));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when one date is null and the other is not', () {
      const withDate = StreakInfo(count: 0, lastActiveLocalDate: LocalDate(0));
      const withoutDate = StreakInfo(count: 0);
      expect(withDate, isNot(equals(withoutDate)));
    });

    test('defaults to no freezes', () {
      const info = StreakInfo(count: 0);
      expect(info.frozenAvailable, 0);
      expect(info.frozenDates, isEmpty);
    });

    test('differs when frozenAvailable differs', () {
      const one = StreakInfo(count: 7, frozenAvailable: 1);
      const none = StreakInfo(count: 7);
      expect(one, isNot(equals(none)));
    });

    test('differs when frozenDates differ', () {
      final withFreeze = StreakInfo(
        count: 3,
        frozenDates: {const LocalDate(1)},
      );
      const withoutFreeze = StreakInfo(count: 3);
      expect(withFreeze, isNot(equals(withoutFreeze)));
    });

    test('ignores the insertion order of frozenDates', () {
      final a = StreakInfo(
        count: 3,
        frozenDates: {const LocalDate(1), const LocalDate(2)},
      );
      final b = StreakInfo(
        count: 3,
        frozenDates: {const LocalDate(2), const LocalDate(1)},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('rejects a negative frozenAvailable', () {
      expect(
        () => StreakInfo(count: 0, frozenAvailable: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('renders count and last active date', () {
      const info = StreakInfo(count: 4, lastActiveLocalDate: LocalDate(0));
      expect(info.toString(), 'StreakInfo(count: 4, lastActive: 1970-01-01)');
    });
  });
}
