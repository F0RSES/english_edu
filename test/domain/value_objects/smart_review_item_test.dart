import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/smart_review_item.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word() => const Word(id: WordId(1), term: 'apple', translation: 'яблоко');

WordProgress progress() => WordProgress(
  wordId: const WordId(1),
  cardState: CardState(
    easePermille: 2000,
    intervalDays: 2,
    repetitions: 1,
    lapses: 2,
    dueAt: now,
  ),
  status: WordStatus.learning,
  firstSeenAt: now,
);

SmartReviewItem item({
  double score = 20,
  String reason = 'Трудное (2 провалов)',
}) => SmartReviewItem(
  word: word(),
  progress: progress(),
  priorityScore: score,
  reason: reason,
);

void main() {
  test('should_be_equal_when_all_fields_match', () {
    expect(item(), item());
    expect(item().hashCode, item().hashCode);
    expect(item(), isNot(item(score: 21)));
    expect(item(), isNot(item(reason: 'Не видел 30 дней')));
  });

  test('should_describe_itself_with_term_and_score', () {
    expect(item().toString(), contains('apple'));
    expect(item().toString(), contains('20'));
    expect(item().toString(), contains('Трудное'));
  });
}
