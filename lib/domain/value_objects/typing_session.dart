import 'package:english_edu/domain/entities/word.dart';
import 'package:meta/meta.dart';

/// Состояние заезда «Typing Speed»: слова, текущая позиция, верные ответы.
@immutable
final class TypingSession {
  /// Создаёт сессию с защитной копией списка слов.
  TypingSession({required List<Word> words, this.index = 0, this.correct = 0})
    : words = List.unmodifiable(words);

  /// Слова заезда в порядке показа.
  final List<Word> words;

  /// Индекс текущего слова.
  final int index;

  /// Сколько слов набрано верно.
  final int correct;

  /// Текущее слово или null, если сессия закончена.
  Word? get current => index < words.length ? words[index] : null;

  /// Все слова пройдены.
  bool get isFinished => index >= words.length;

  /// Сколько слов всего.
  int get length => words.length;

  /// Сдвигает сессию на одно слово вперёд.
  TypingSession next({required bool wasCorrect}) => TypingSession(
    words: words,
    index: index + 1,
    correct: correct + (wasCorrect ? 1 : 0),
  );

  @override
  String toString() => 'TypingSession($index/${words.length}, $correct верно)';
}
