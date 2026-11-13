import 'dart:math';

import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/memory_card.dart';
import 'package:english_edu/domain/value_objects/memory_game.dart';

/// Собирает партию «Memory» из словаря (ADR-036).
///
/// Пары берутся случайно, но детерминированно при инжектированном `Random`:
/// тесты подставляют seed и получают один и тот же расклад. Слова — строго
/// выбранного уровня (Phase 27a).
final class GenerateMemoryGame {
  /// Создаёт use case.
  const GenerateMemoryGame({
    required WordRepository words,
    required SettingsRepository settings,
    required Random random,
    this.pairsCount = 8,
  }) : _words = words,
       _settings = settings,
       _random = random;

  final WordRepository _words;
  final SettingsRepository _settings;
  final Random _random;

  /// Сколько пар нужно в идеале.
  final int pairsCount;

  /// Возвращает новую партию.
  ///
  /// Если слов меньше, чем [pairsCount], партия собирается из того, что есть:
  /// пустой словарь даёт пустую партию, а не исключение — экран покажет
  /// «добавьте слова» вместо падения.
  Future<MemoryGame> call() async {
    final level = (await _settings.get()).preferredLevel;
    final all = await _words.getByLevel(level);
    if (all.isEmpty) {
      return MemoryGame(cards: const []);
    }

    final shuffled = [...all]..shuffle(_random);
    final selected = shuffled.take(pairsCount).toList();

    final cards = <MemoryCard>[];
    var id = 0;
    for (var pairId = 0; pairId < selected.length; pairId++) {
      final word = selected[pairId];
      cards
        ..add(
          MemoryCard(
            id: id++,
            pairId: pairId,
            text: word.term,
            isEnglish: true,
          ),
        )
        ..add(
          MemoryCard(
            id: id++,
            pairId: pairId,
            text: word.translation,
            isEnglish: false,
          ),
        );
    }
    cards.shuffle(_random);

    return MemoryGame(cards: cards);
  }
}
