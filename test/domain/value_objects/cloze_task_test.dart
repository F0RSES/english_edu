import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:test/test.dart';

void main() {
  group('ClozeTask.fromJson', () {
    test('parses sentence and answer', () {
      final task = ClozeTask.fromJson(const {
        'sentence': 'I ___ apples every day.',
        'answer': 'eat',
      });

      expect(
        task,
        const ClozeTask(sentence: 'I ___ apples every day.', answer: 'eat'),
      );
    });

    test('rejects a missing sentence', () {
      expect(
        () => ClozeTask.fromJson(const {'answer': 'eat'}),
        throwsFormatException,
      );
    });

    test('rejects a blank answer', () {
      expect(
        () => ClozeTask.fromJson(const {
          'sentence': 'I ___ apples.',
          'answer': '   ',
        }),
        throwsFormatException,
      );
    });
  });

  test('equality is structural', () {
    const left = ClozeTask(sentence: 'I ___ it.', answer: 'like');
    const right = ClozeTask(sentence: 'I ___ it.', answer: 'like');
    const other = ClozeTask(sentence: 'I ___ it.', answer: 'love');

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    expect(left, isNot(other));
  });
}
