import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:test/test.dart';

void main() {
  group('fromLabel', () {
    test('parses every level label', () {
      for (final level in CefrLevel.values) {
        expect(CefrLevel.fromLabel(level.label), level);
      }
    });

    test('ignores the case of the label', () {
      expect(CefrLevel.fromLabel('b2'), CefrLevel.b2);
      expect(CefrLevel.fromLabel('C1'), CefrLevel.c1);
    });

    test('throws on an unknown label', () {
      expect(() => CefrLevel.fromLabel('D1'), throwsArgumentError);
    });

    test('throws on an empty label', () {
      expect(() => CefrLevel.fromLabel(''), throwsArgumentError);
    });
  });

  group('order', () {
    test('keeps the scale from A0 to C2', () {
      expect(CefrLevel.a0.index, lessThan(CefrLevel.a1.index));
      expect(CefrLevel.a2.index, lessThan(CefrLevel.b1.index));
      expect(CefrLevel.b1.index, lessThan(CefrLevel.b2.index));
      expect(CefrLevel.b2.index, lessThan(CefrLevel.c1.index));
      expect(CefrLevel.c1.index, lessThan(CefrLevel.c2.index));
      expect(CefrLevel.values, hasLength(7));
    });
  });

  test('every level has a non-empty description', () {
    for (final level in CefrLevel.values) {
      expect(level.description, isNotEmpty);
    }
  });
}
