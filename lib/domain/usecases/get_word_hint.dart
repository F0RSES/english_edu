import 'package:english_edu/domain/repositories/word_hint_repository.dart';
import 'package:english_edu/domain/services/hint_generator.dart';
import 'package:english_edu/domain/value_objects/word_hint.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Отдаёт подсказку к слову: кэш → AI → кэш.
///
/// Сначала смотрит в БД. Запись считается валидной только при совпадении
/// [WordHint.term]: если слово отредактировали, старая ассоциация относилась к
/// другому написанию и запрашивается заново.
///
/// Ошибка генератора **не** кэшируется: исключение пробрасывается до записи,
/// поэтому следующий вызов снова попробует сеть.
final class GetWordHint {
  /// Создаёт use case.
  const GetWordHint({
    required WordHintRepository hints,
    required HintGenerator generator,
    required DateTime Function() clock,
  }) : _hints = hints,
       _generator = generator,
       _clock = clock;

  final WordHintRepository _hints;
  final HintGenerator _generator;
  final DateTime Function() _clock;

  /// Возвращает подсказку для [wordId] с текущим написанием [term].
  ///
  /// Бросает исключение генератора, если кэша нет и провайдер недоступен.
  Future<String> call(WordId wordId, String term) async {
    final cached = await _hints.getByWordId(wordId);
    if (cached != null && cached.term == term) {
      return cached.hintText;
    }

    final generated = await _generator.generate(term);
    await _hints.upsert(
      WordHint(
        wordId: wordId,
        term: term,
        hintText: generated,
        createdAtUtc: _clock().toUtc(),
      ),
    );
    return generated;
  }
}
