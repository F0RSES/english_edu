import 'package:english_edu/domain/entities/word.dart';
import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Один ответ в заезде «Typing Speed» (Phase 55b).
///
/// Снимок ответа: что ввёл пользователь, правильное слово, перевод,
/// верность и момент ответа (UTC). [word] — исходная статья словаря:
/// нужна шторке результатов для примера и добавления в «Изучаю».
/// `correctWord`/`translation` выводятся из [word] при создании.
@immutable
final class TypingResult {
  /// Создаёт результат; [timestamp] должен быть в UTC.
  TypingResult({
    required this.word,
    required this.userInput,
    required this.isCorrect,
    required DateTime timestamp,
  }) : correctWord = word.term,
       translation = word.translation,
       timestamp = _requireUtc(timestamp, 'timestamp');

  /// Исходная статья словаря (пример, добавление в «Изучаю»).
  final Word word;

  /// Что ввёл пользователь.
  final String userInput;

  /// Правильный ответ — термин слова.
  final String correctWord;

  /// Перевод слова.
  final String translation;

  /// Верен ли ответ.
  final bool isCorrect;

  /// Момент ответа, UTC; задаёт порядок «по очереди».
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingResult &&
          word == other.word &&
          userInput == other.userInput &&
          isCorrect == other.isCorrect &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(word, userInput, isCorrect, timestamp);

  @override
  String toString() => 'TypingResult($correctWord, correct: $isCorrect)';
}
