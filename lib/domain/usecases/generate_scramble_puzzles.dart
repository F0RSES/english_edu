import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/scramble_puzzle.dart';

/// Собирает задания «Собери слово» из словаря (ADR-027).
///
/// Работает офлайн и без AI: слова и переводы уже в базе.  приходит
/// снаружи — тесты подставляют `Random(seed)`, иначе перестановка букв была бы
/// недетерминированной.
final class GenerateScramblePuzzles {
  /// Создаёт генератор.
  const GenerateScramblePuzzles({
    required WordRepository words,
    required SettingsRepository settings,
    required Random random,
  }) : _words = words,
       _settings = settings,
       _random = random;

  /// Сколько попыток перемешать, прежде чем сдаться.
  ///
  /// Сдаться иногда необходимо: у слова из одной буквы (`a`, `i`) или из
  /// одинаковых букв перемешанный вариант физически совпадает с решением.
  static const _maxShuffleAttempts = 10;

  /// Слова короче двух букв отбрасываются: перестановки у них нет.
  static const _minTermLength = 2;

  final WordRepository _words;
  final SettingsRepository _settings;
  final Random _random;

  /// Возвращает до [count] заданий в случайном порядке слов.
  ///
  /// Слова берутся строго выбранного уровня (Phase 27a).
  ///
  /// Пустой словарь даёт пустой список: экран покажет состояние ошибки, а не
  /// пустую игру. `scrambled` не совпадает с `solution`, если это возможно
  /// (см. `_maxShuffleAttempts`).
  Future<List<ScramblePuzzle>> call({int count = 10}) async {
    if (count <= 0) {
      return const [];
    }
    final level = (await _settings.get()).preferredLevel;
    final allWords = await _words.getByLevel(level);
    final eligible = [
      for (final word in allWords)
        if (word.term.trim().length >= _minTermLength) word,
    ];
    if (eligible.isEmpty) {
      return const [];
    }

    final shuffled = [...eligible]..shuffle(_random);
    return [for (final word in shuffled.take(count)) _puzzleFor(word)];
  }

  ScramblePuzzle _puzzleFor(Word word) {
    final solution = word.term.trim().toLowerCase();
    final letters = solution.split('');
    var scrambled = [...letters]..shuffle(_random);
    var attempts = 1;
    while (scrambled.join() == solution && attempts < _maxShuffleAttempts) {
      scrambled = [...letters]..shuffle(_random);
      attempts++;
    }
    return ScramblePuzzle(
      word: word.id,
      translation: word.translation,
      scrambled: scrambled,
      solution: solution,
    );
  }
}
