import 'dart:math';

import 'package:english_edu/domain/entities/word.dart';
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
    required Random random,
  }) : _words = words,
       _random = random;

  final WordRepository _words;
  final Random _random;

  /// Возвращает до [count] случайных слов в случайном порядке.
  ///
  /// Пустой словарь даёт пустой список: экран покажет ошибку, а не пустой
  /// диктант без слов.
  Future<List<Word>> call({int count = 10}) async {
    if (count <= 0) {
      return const [];
    }
    final allWords = await _words.getAll();
    if (allWords.isEmpty) {
      return const [];
    }
    final shuffled = [...allWords]..shuffle(_random);
    return shuffled.take(count).toList();
  }
}
