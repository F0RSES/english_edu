import 'package:english_edu/domain/repositories/word_translation_repository.dart';
import 'package:english_edu/domain/services/word_translator.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';

/// Словарный перевод слова: кэш → AI → кэш (BL-96).
///
/// Реализует [TranslationGenerator], поэтому DI подставляет его вместо
/// `AiClient` без правок UI: виджеты читают тот же провайдер.
///
/// Ошибка генератора **не** кэшируется: исключение пробрасывается до записи,
/// поэтому следующий вызов снова попробует сеть (паттерн `GetWordHint`).
final class TranslateWord implements TranslationGenerator {
  /// Создаёт use case.
  const TranslateWord({
    required WordTranslationRepository translations,
    required TranslationGenerator generator,
    required DateTime Function() clock,
  }) : _translations = translations,
       _generator = generator,
       _clock = clock;

  final WordTranslationRepository _translations;
  final TranslationGenerator _generator;
  final DateTime Function() _clock;

  @override
  Future<WordTranslation> translate(String word) async {
    final cached = await _translations.findByTerm(word);
    if (cached != null) {
      return cached;
    }

    final generated = await _generator.translate(word);
    await _translations.upsert(word, generated, createdAtUtc: _clock().toUtc());
    return generated;
  }
}
