import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:meta/meta.dart';

/// Задание мини-игры «Собери слово» (ADR-027).
///
/// [scrambled] — буквы [solution] в случайном порядке; [translation] —
/// подсказка на русском. Игра работает офлайн: задание собирается из
/// локального словаря, сеть и AI не участвуют.
///
/// Порядок [scrambled] — часть задания, поэтому он входит в равенство: два
/// пазла одного слова с разной перестановкой — разные пазлы.
@immutable
final class ScramblePuzzle {
  /// Создаёт задание; [scrambled] копируется в unmodifiable.
  ///
  /// Not `const`: список букв копируется, как в `TodayQueue`.
  ScramblePuzzle({
    required this.word,
    required this.translation,
    required List<String> scrambled,
    required this.solution,
  }) : scrambled = List.unmodifiable(scrambled);

  /// Слово, к которому относится задание.
  final WordId word;

  /// Перевод-подсказка, например «яблоко».
  final String translation;

  /// Перемешанные буквы решения.
  final List<String> scrambled;

  /// Правильный ответ в нижнем регистре — по нему идёт сравнение.
  final String solution;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScramblePuzzle &&
          word == other.word &&
          translation == other.translation &&
          solution == other.solution &&
          _sameLetters(scrambled, other.scrambled);

  @override
  int get hashCode =>
      Object.hash(word, translation, solution, Object.hashAll(scrambled));

  @override
  String toString() =>
      'ScramblePuzzle($solution → ${scrambled.join()}, "$translation")';

  static bool _sameLetters(List<String> left, List<String> right) {
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
