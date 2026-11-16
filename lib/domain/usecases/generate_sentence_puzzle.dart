import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/services/sentence_generator.dart';
import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';

/// Собирает задание «Собери предложение» (Phase 35).
///
/// Офлайн-путь: у слова есть `exampleSentence` — оно становится заданием,
/// сеть не используется, перевод слова служит подсказкой. Если примера нет
/// (null или пустой) — задание генерирует AI. `Random` приходит снаружи:
/// тесты подставляют `Random(seed)`, иначе перестановка недетерминирована.
final class GenerateSentencePuzzle {
  /// Создаёт генератор.
  const GenerateSentencePuzzle({
    required WordRepository words,
    required SentenceGenerator generator,
    required SettingsRepository settings,
    required Random random,
  }) : _words = words,
       _generator = generator,
       _settings = settings,
       _random = random;

  /// Сколько попыток перемешать, прежде чем сдаться (паттерн Scramble).
  ///
  /// У примера из одного слова перестановка физически совпадает с решением.
  static const _maxShuffleAttempts = 10;

  final WordRepository _words;
  final SentenceGenerator _generator;
  final SettingsRepository _settings;
  final Random _random;

  /// Возвращает задание по случайному слову выбранного уровня.
  ///
  /// Пустой словарь — [StateError]: экран покажет состояние ошибки с retry,
  /// а не пустую игру.
  Future<SentencePuzzle> call() async {
    final level = (await _settings.get()).preferredLevel;
    final allWords = await _words.getByLevel(level);
    if (allWords.isEmpty) {
      throw StateError('dictionary is empty');
    }
    final word = allWords[_random.nextInt(allWords.length)];
    final example = word.exampleSentence?.trim() ?? '';
    if (example.isEmpty) {
      return await _generator.generateSentencePuzzle(
        word.term,
        level: level.label,
      );
    }
    return _offlinePuzzle(word, example);
  }

  /// Задание из примера словаря: пробелы нормализуются, чтобы собранный
  /// ответ можно было сравнить с решением пословно.
  SentencePuzzle _offlinePuzzle(Word word, String example) {
    final tokens = example.split(RegExp(r'\s+'));
    final sentence = tokens.join(' ');
    var shuffled = [...tokens]..shuffle(_random);
    var attempts = 1;
    while (shuffled.join(' ') == sentence && attempts < _maxShuffleAttempts) {
      shuffled = [...tokens]..shuffle(_random);
      attempts++;
    }
    return SentencePuzzle(
      sentence: sentence,
      shuffledWords: shuffled,
      translation: word.translation,
    );
  }
}
