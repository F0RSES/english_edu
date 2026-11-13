import 'package:english_edu/core/text/plural.dart';
import 'package:flutter_test/flutter_test.dart';

String day(int n) => pluralize(n, one: 'день', few: 'дня', many: 'дней');

void main() {
  test('uses the "one" form for 1 and 21', () {
    expect(day(1), 'день');
    expect(day(21), 'день');
  });

  test('uses the "few" form for 2..4 and 22', () {
    expect(day(2), 'дня');
    expect(day(3), 'дня');
    expect(day(4), 'дня');
    expect(day(22), 'дня');
  });

  test('uses the "many" form for 5..10', () {
    expect(day(5), 'дней');
    expect(day(10), 'дней');
  });

  test('treats 11..14 as "many" despite the last digit', () {
    expect(day(11), 'дней');
    expect(day(12), 'дней');
    expect(day(13), 'дней');
    expect(day(14), 'дней');
    expect(day(111), 'дней');
  });

  test('treats 0 and 100 as "many"', () {
    expect(day(0), 'дней');
    expect(day(100), 'дней');
  });

  test('works for other words with the same rules', () {
    String word(int n) =>
        pluralize(n, one: 'слово', few: 'слова', many: 'слов');

    expect(word(1), 'слово');
    expect(word(2), 'слова');
    expect(word(5), 'слов');
    expect(word(11), 'слов');
    expect(word(21), 'слово');
  });
}
