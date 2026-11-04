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

    test('renders count and last active date', () {
      const info = StreakInfo(count: 4, lastActiveLocalDate: LocalDate(0));
      expect(
        info.toString(),
        'StreakInfo(count: 4, lastActive: 1970-01-01)',
      );
    });
  });
}
