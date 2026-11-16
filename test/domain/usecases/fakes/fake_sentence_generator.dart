import 'package:english_edu/domain/services/sentence_generator.dart';
import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';

/// Генератор без сети: отдаёт готовое задание, считает вызовы, умеет падать.
final class FakeSentenceGenerator implements SentenceGenerator {
  /// Создаёт фейк; [puzzle] — что вернуть, [error] — что бросить.
  FakeSentenceGenerator({SentencePuzzle? puzzle, this.error})
    : puzzle =
          puzzle ??
          SentencePuzzle(
            sentence: 'I eat an apple every day',
            shuffledWords: const ['day', 'eat', 'an', 'I', 'every', 'apple'],
            translation: 'Я ем яблоко каждый день',
          );

  /// Задание, которое возвращается на каждый вызов.
  final SentencePuzzle puzzle;

  /// Ошибка вместо задания; null — успех.
  final Exception? error;

  /// Сколько раз вызывали генератор.
  int calls = 0;

  /// Слова, которые пришли в генератор, в порядке вызовов.
  final List<String> words = [];

  /// Уровни, которые пришли в генератор, в порядке вызовов.
  final List<String> levels = [];

  @override
  Future<SentencePuzzle> generateSentencePuzzle(
    String word, {
    required String level,
  }) async {
    calls++;
    words.add(word);
    levels.add(level);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return puzzle;
  }
}
