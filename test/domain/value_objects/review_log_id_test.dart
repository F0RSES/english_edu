import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewLogId', () {
    test('stores the given value', () {
      const id = ReviewLogId(11);
      expect(id.value, 11);
    });

    test('is equal and has the same hash for equal values', () {
      const a = ReviewLogId(5);
      const b = ReviewLogId(5);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('is not equal for different values', () {
      expect(const ReviewLogId(5), isNot(equals(const ReviewLogId(6))));
    });

    test('orders by value', () {
      expect(const ReviewLogId(1).compareTo(const ReviewLogId(2)), lessThan(0));
      expect(
        const ReviewLogId(2).compareTo(const ReviewLogId(1)),
        greaterThan(0),
      );
      expect(const ReviewLogId(2).compareTo(const ReviewLogId(2)), 0);
    });

    test('renders as ReviewLogId(value)', () {
      expect(const ReviewLogId(9).toString(), 'ReviewLogId(9)');
    });

    test('rejects a negative value', () {
      expect(() => ReviewLogId(-1), throwsA(isA<AssertionError>()));
    });
  });
}
