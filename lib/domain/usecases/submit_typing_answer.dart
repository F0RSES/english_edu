import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';

/// Проверяет введённое слово и сдвигает сессию (ADR-037).
///
/// Чистая функция: ни таймеров, ни хранилища. Сравнение — `trim` + нижний
/// регистр, потому что клавиатура легко добавляет пробел или заглавную букву,
/// и это не должно считаться ошибкой. Синонимы слова — тоже верный ответ
/// (Phase 36a): «еда» — это и `meal`, и `food`.
final class SubmitTypingAnswer {
  /// Создаёт use case.
  const SubmitTypingAnswer();

  /// Совпадает ли [input] с термином или синонимом [word].
  ///
  /// Статический метод переиспользуется экраном: вспышка/карточка ошибки и
  /// сдвиг сессии должны считать правильность одинаково.
  static bool matches(Word word, String input) {
    final typed = input.trim().toLowerCase();
    if (typed == word.term.trim().toLowerCase()) {
      return true;
    }
    return word.synonyms.any(
      (synonym) => synonym.trim().toLowerCase() == typed,
    );
  }

  /// Возвращает сессию, сдвинутую на одно слово.
  TypingSession call(TypingSession session, String input) {
    final word = session.current;
    if (word == null) {
      return session;
    }
    return session.next(wasCorrect: matches(word, input));
  }
}
