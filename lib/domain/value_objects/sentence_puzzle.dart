import 'package:meta/meta.dart';

/// Задание игры «Собери предложение» (Phase 35).
///
/// [sentence] — правильный порядок слов, [shuffledWords] — те же слова в
/// случайном порядке, [translation] — подсказка на русском. Порядок
/// [shuffledWords] — часть задания, поэтому входит в равенство: два пазла
/// одного предложения с разной перестановкой — разные пазлы.
@immutable
final class SentencePuzzle {
  /// Создаёт задание; [shuffledWords] копируется в unmodifiable.
  ///
  /// Not `const`: список слов копируется, как в `ScramblePuzzle`.
  SentencePuzzle({
    required this.sentence,
    required List<String> shuffledWords,
    required this.translation,
  }) : shuffledWords = List.unmodifiable(shuffledWords);

  /// Правильное предложение — по нему сравнивается собранный ответ.
  final String sentence;

  /// Слова предложения в случайном порядке.
  final List<String> shuffledWords;

  /// Перевод-подсказка на русском.
  final String translation;

  /// Returns a copy with the given fields replaced.
  SentencePuzzle copyWith({
    String? sentence,
    List<String>? shuffledWords,
    String? translation,
  }) => SentencePuzzle(
    sentence: sentence ?? this.sentence,
    shuffledWords: shuffledWords ?? this.shuffledWords,
    translation: translation ?? this.translation,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SentencePuzzle &&
          sentence == other.sentence &&
          translation == other.translation &&
          _sameWords(shuffledWords, other.shuffledWords);

  @override
  int get hashCode =>
      Object.hash(sentence, translation, Object.hashAll(shuffledWords));

  @override
  String toString() =>
      'SentencePuzzle("$sentence" → ${shuffledWords.join(' ')}, '
      '"$translation")';

  static bool _sameWords(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
