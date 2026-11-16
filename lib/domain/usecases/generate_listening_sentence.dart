import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/services/sentence_generator.dart';
import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';

/// Генерирует задание «Аудио-диктант предложений» (Phase 36b).
///
/// Похож на `GenerateSentencePuzzle`, но без перемешивания: предложение
/// звучит через TTS и вводится целиком, поэтому `shuffledWords` пуст.
/// Офлайн-путь — `exampleSentence` словаря (перевод слова служит подсказкой);
/// если примера нет — генерирует AI. `Random` приходит снаружи: тесты
/// подставляют `Random(seed)`.
final class GenerateListeningSentence {
  /// Создаёт генератор.
  const GenerateListeningSentence({
    required WordRepository words,
    required SentenceGenerator generator,
    required SettingsRepository settings,
    required Random random,
  }) : _words = words,
       _generator = generator,
       _settings = settings,
       _random = random;

  final WordRepository _words;
  final SentenceGenerator _generator;
  final SettingsRepository _settings;
  final Random _random;

  /// Возвращает предложение по случайному слову выбранного уровня.
  ///
  /// Пустой словарь — [StateError]: экран покажет состояние ошибки с retry.
  Future<SentencePuzzle> call() async {
    final level = (await _settings.get()).preferredLevel;
    final allWords = await _words.getByLevel(level);
    if (allWords.isEmpty) {
      throw StateError('dictionary is empty');
    }
    final word = allWords[_random.nextInt(allWords.length)];
    final example = word.exampleSentence?.trim() ?? '';
    if (example.isEmpty) {
      final generated = await _generator.generateSentencePuzzle(
        word.term,
        level: level.label,
      );
      // Диктанту перемешка не нужна: предложение вводится целиком.
      return generated.copyWith(shuffledWords: const []);
    }
    return _offlinePuzzle(word, example);
  }

  /// Задание из примера словаря: пробелы нормализуются, чтобы введённый
  /// ответ можно было сравнить с решением пословно.
  SentencePuzzle _offlinePuzzle(Word word, String example) {
    final sentence = example.split(RegExp(r'\s+')).join(' ');
    return SentencePuzzle(
      sentence: sentence,
      shuffledWords: const [],
      translation: word.translation,
    );
  }
}
