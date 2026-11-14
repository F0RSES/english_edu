import 'package:english_edu/domain/services/word_translator.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';

/// Переводчик без сети: отдаёт готовый перевод, считает вызовы, умеет падать.
final class FakeTranslationGenerator implements TranslationGenerator {
  /// Создаёт фейк; [translation] — что вернуть, [error] — что бросить.
  FakeTranslationGenerator({
    this.translation = const WordTranslation(text: 'учреждение'),
    this.error,
  });

  /// Перевод, который возвращается на каждый вызов.
  final WordTranslation translation;

  /// Ошибка вместо перевода; null — успех.
  final Exception? error;

  /// Сколько раз вызывали переводчик.
  int calls = 0;

  /// Слова, которые пришли в [translate], в порядке вызовов.
  final List<String> words = [];

  @override
  Future<WordTranslation> translate(String word) async {
    calls++;
    words.add(word);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return translation;
  }
}
