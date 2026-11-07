import 'package:english_edu/domain/value_objects/typing_session.dart';

/// Проверяет введённое слово и сдвигает сессию (ADR-037).
///
/// Чистая функция: ни таймеров, ни хранилища. Сравнение — `trim` + нижний
/// регистр, потому что клавиатура легко добавляет пробел или заглавную букву,
/// и это не должно считаться ошибкой.
final class SubmitTypingAnswer {
  /// Создаёт use case.
  const SubmitTypingAnswer();

  /// Возвращает сессию, сдвинутую на одно слово.
  TypingSession call(TypingSession session, String input) {
    final word = session.current;
    if (word == null) {
      return session;
    }
    final typed = input.trim().toLowerCase();
    final expected = word.term.trim().toLowerCase();
    return session.next(wasCorrect: typed == expected);
  }
}
