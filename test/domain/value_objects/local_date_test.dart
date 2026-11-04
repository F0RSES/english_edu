import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

void main() {
  group('LocalDate', () {
    test('maps the epoch start to day zero', () {
      final date = LocalDate.fromDateTime(DateTime.utc(1970));
      expect(date, equals(const LocalDate(0)));
      expect(date.daysSinceEpoch, 0);
    });

    test('maps 2024-01-01 to 19723 and 2024-01-02 to 19724', () {
      expect(
        LocalDate.fromDateTime(DateTime.utc(2024)).daysSinceEpoch,
        19723,
      );
      expect(
        LocalDate.fromDateTime(DateTime.utc(2024, 1, 2)).daysSinceEpoch,
        19724,
      );
    });

    test('takes year, month and day as written, whatever the zone is', () {
      final local = DateTime(2024, 1, 1, 10);
      final utc = DateTime.utc(2024, 1, 1, 10);
      expect(LocalDate.fromDateTime(local), equals(const LocalDate(19723)));
      expect(LocalDate.fromDateTime(utc), equals(const LocalDate(19723)));
    });

    test('today takes the day from a local instant', () {
      final date = LocalDate.today(now: DateTime(2024, 5, 15, 10));
      expect(date, equals(const LocalDate(19858)));
    });

    test('today takes the day from a UTC instant without converting', () {
      final date = LocalDate.today(now: DateTime.utc(2024, 5, 15, 10));
      expect(date, equals(const LocalDate(19858)));
    });

    test('addDays crosses a month boundary', () {
      final jan31 = LocalDate.fromDateTime(DateTime.utc(2024, 1, 31));
      expect(jan31.addDays(1).toString(), '2024-02-01');
    });

    test('addDays crosses a year boundary', () {
      final dec31 = LocalDate.fromDateTime(DateTime.utc(2024, 12, 31));
      expect(dec31.addDays(1).toString(), '2025-01-01');
    });

    test('addDays handles negative shifts', () {
      final jan1 = LocalDate.fromDateTime(DateTime.utc(2024));
      expect(jan1.addDays(-1).toString(), '2023-12-31');
      expect(const LocalDate(0).addDays(-1).toString(), '1969-12-31');
    });

    test('orders by days since epoch', () {
      expect(const LocalDate(1).compareTo(const LocalDate(2)), lessThan(0));
      expect(const LocalDate(2).compareTo(const LocalDate(1)), greaterThan(0));
      expect(const LocalDate(2).compareTo(const LocalDate(2)), 0);
    });

    test('renders an ISO date', () {
      expect(const LocalDate(0).toString(), '1970-01-01');
      expect(const LocalDate(19723).toString(), '2024-01-01');
    });

    test('is equal and has the same hash for equal days', () {
      const a = LocalDate(19723);
      const b = LocalDate(19723);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(const LocalDate(19724))));
    });
  });
}
