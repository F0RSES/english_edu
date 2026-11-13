import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

Word word(int id) => Word(
      id: WordId(id),
      term: 'term$id',
      translation: 'перевод$id',
    );

void main() {
  group('TodayQueue', () {
    test('can be empty', () {
      final queue = TodayQueue(due: const [], newWords: const []);
      expect(queue.due, isEmpty);
      expect(queue.newWords, isEmpty);
      expect(queue.all, isEmpty);
      expect(queue.length, 0);
    });

    test('takes a defensive copy of both lists', () {
      final due = [word(1)];
      final fresh = [word(2)];
      final queue = TodayQueue(due: due, newWords: fresh);

      due.add(word(3));
      fresh.add(word(4));

      expect(queue.due, [word(1)]);
      expect(queue.newWords, [word(2)]);
      expect(queue.length, 2);
    });

    test('exposes both lists as unmodifiable', () {
      final queue = TodayQueue(due: [word(1)], newWords: [word(2)]);
      expect(() => queue.due.add(word(3)), throwsUnsupportedError);
      expect(() => queue.newWords.add(word(3)), throwsUnsupportedError);
      expect(() => queue.all.add(word(3)), throwsUnsupportedError);
    });

    test('all concatenates due before new', () {
      final queue = TodayQueue(
        due: [word(1), word(2)],
        newWords: [word(3)],
      );
      expect(
        queue.all.map((w) => w.id.value).toList(),
        [1, 2, 3],
      );
      expect(queue.length, 3);
    });

    test('is equal and has the same hash for equal contents', () {
      final a = TodayQueue(due: [word(1)], newWords: [word(2)]);
      final b = TodayQueue(due: [word(1)], newWords: [word(2)]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs by element order', () {
      final ascending = TodayQueue(
        due: [word(1), word(2)],
        newWords: const [],
      );
      final descending = TodayQueue(
        due: [word(2), word(1)],
        newWords: const [],
      );
      expect(ascending, isNot(equals(descending)));
    });

    test('differs by length and by section', () {
      final base = TodayQueue(due: [word(1)], newWords: [word(2)]);
      expect(
        base,
        isNot(equals(TodayQueue(due: [word(1)], newWords: const []))),
      );
      expect(
        base,
        isNot(equals(TodayQueue(due: const [], newWords: [word(2)]))),
      );
      expect(
        base,
        isNot(equals(TodayQueue(due: [word(1)], newWords: [word(2), word(3)]))),
      );
    });

    test('renders both counts', () {
      final queue = TodayQueue(due: [word(1)], newWords: [word(2), word(3)]);
      expect(queue.toString(), 'TodayQueue(due: 1, new: 2)');
    });
  });
}
