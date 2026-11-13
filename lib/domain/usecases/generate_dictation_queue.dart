import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';

/// Собирает очередь аудио-диктанта (ADR-028).
///
/// 10 случайных слов словаря: TTS читает слово, пользователь печатает
/// услышанное. Сеть не нужна — слова и озвучка локальные.
///
///  приходит снаружи: тесты подставляют `Random(seed)` и получают
/// детерминированный порядок.
final class GenerateDictationQueue {
  /// Создаёт генератор.
  const GenerateDictationQueue({
    required WordRepository words,
    required SettingsRepository settings,
    required Random random,
  }) : _words = words,
       _settings = settings,
       _random = random;

  final WordRepository _words;
  final SettingsRepository _settings;
  final Random _random;

  /// Возвращает до [count] случайных слов в случайном порядке.
  ///
  /// Слова берутся строго выбранного уровня (Phase 27a). Пустой словарь даёт
  /// пустой список: экран покажет ошибку, а не пустой диктант без слов.
  Future<List<Word>> call({int count = 10}) async {
    if (count <= 0) {
      return const [];
    }
    final level = (await _settings.get()).preferredLevel;
    final allWords = await _words.getByLevel(level);
    if (allWords.isEmpty) {
      return const [];
    }
    final shuffled = [...allWords]..shuffle(_random);
    return shuffled.take(count).toList();
  }
}
