import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

void main() {
  group('WordId', () {
    test('stores the given value', () {
      const id = WordId(42);
      expect(id.value, 42);
    });

    test('is equal and has the same hash for equal values', () {
      const a = WordId(7);
      const b = WordId(7);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('is not equal for different values', () {
      expect(const WordId(7), isNot(equals(const WordId(8))));
    });

    test('orders by value', () {
      expect(const WordId(1).compareTo(const WordId(2)), lessThan(0));
      expect(const WordId(2).compareTo(const WordId(1)), greaterThan(0));
      expect(const WordId(2).compareTo(const WordId(2)), 0);
    });

    test('renders as WordId(value)', () {
      expect(const WordId(3).toString(), 'WordId(3)');
    });

    test('rejects a negative value', () {
      expect(() => WordId(-1), throwsA(isA<AssertionError>()));
    });
  });
}
