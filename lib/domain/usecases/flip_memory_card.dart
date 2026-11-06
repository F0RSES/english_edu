import 'package:english_edu/domain/value_objects/memory_card.dart';
import 'package:english_edu/domain/value_objects/memory_game.dart';

/// Открывает карточку и проверяет пару (ADR-036).
///
/// Чистая функция без таймеров и Flutter: задержку перед закрытием несовпавших
/// карточек держит UI, а правило «что считать ходом» живёт здесь и покрывается
/// тестами.
final class FlipMemoryCard {
  /// Создаёт use case.
  const FlipMemoryCard();

  /// Открывает карточку [cardId].
  ///
  /// Ничего не делает, если карточка уже открыта или найдена, а также если
  /// две карточки уже открыты и ждут проверки: иначе третья перезаписала бы
  /// состояние пары.
  MemoryGame call(MemoryGame game, int cardId) {
    if (game.flippedCardIds.length >= 2) {
      return game;
    }

    final index = game.cards.indexWhere((card) => card.id == cardId);
    if (index < 0) {
      return game;
    }
    final card = game.cards[index];
    if (card.state != MemoryCardState.hidden) {
      return game;
    }

    final cards = [
      for (var position = 0; position < game.cards.length; position++)
        if (position == index)
          card.copyWith(state: MemoryCardState.flipped)
        else
          game.cards[position],
    ];
    final flipped = [...game.flippedCardIds, cardId];

    if (flipped.length == 2) {
      final first = cards.firstWhere((item) => item.id == flipped.first);
      if (first.pairId == card.pairId) {
        for (var position = 0; position < cards.length; position++) {
          if (cards[position].pairId == card.pairId) {
            cards[position] = cards[position].copyWith(
              state: MemoryCardState.matched,
            );
          }
        }
        flipped.clear();
      }
    }

    final won =
        cards.isNotEmpty &&
        cards.every((item) => item.state == MemoryCardState.matched);

    return game.copyWith(
      cards: cards,
      flippedCardIds: flipped,
      moves: game.moves + 1,
      isWon: won,
    );
  }

  /// Закрывает несовпавшие карточки.
  ///
  /// Вызывается UI через 800 мс: домен не знает про задержки, но знает, как
  /// вернуть состояние в исходное.
  MemoryGame resetFlipped(MemoryGame game) => game.copyWith(
    cards: [
      for (final card in game.cards)
        if (card.state == MemoryCardState.flipped)
          card.copyWith(state: MemoryCardState.hidden)
        else
          card,
    ],
    flippedCardIds: const [],
  );
}
