import 'dart:math';

import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/typing_session.dart';

/// Собирает заезд «Typing Speed» из словаря (ADR-037).
///
/// Слова берутся строго выбранного уровня (Phase 27a).
final class GenerateTypingSession {
  /// Создаёт use case.
  const GenerateTypingSession({
    required WordRepository words,
    required SettingsRepository settings,
    required Random random,
    this.wordsCount = 10,
  }) : _words = words,
       _settings = settings,
       _random = random;

  final WordRepository _words;
  final SettingsRepository _settings;
  final Random _random;

  /// Сколько слов в заезде.
  final int wordsCount;

  /// Возвращает новую сессию; при нехватке слов берёт сколько есть.
  Future<TypingSession> call() async {
    final level = (await _settings.get()).preferredLevel;
    final all = await _words.getByLevel(level);
    if (all.isEmpty) {
      return TypingSession(words: const []);
    }
    final shuffled = [...all]..shuffle(_random);
    return TypingSession(words: shuffled.take(wordsCount).toList());
  }
}
