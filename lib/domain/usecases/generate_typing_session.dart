import 'dart:math';

import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';

/// Собирает заезд «Typing Speed» из словаря (ADR-037).
final class GenerateTypingSession {
  /// Создаёт use case.
  const GenerateTypingSession({
    required WordRepository words,
    required Random random,
    this.wordsCount = 10,
  }) : _words = words,
       _random = random;

  final WordRepository _words;
  final Random _random;

  /// Сколько слов в заезде.
  final int wordsCount;

  /// Возвращает новую сессию; при нехватке слов берёт сколько есть.
  Future<TypingSession> call() async {
    final all = await _words.getAll();
    if (all.isEmpty) {
      return TypingSession(words: const []);
    }
    final shuffled = [...all]..shuffle(_random);
    return TypingSession(words: shuffled.take(wordsCount).toList());
  }
}
