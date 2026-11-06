import 'package:english_edu/domain/usecases/flip_memory_card.dart';
import 'package:english_edu/domain/value_objects/memory_card.dart';
import 'package:english_edu/domain/value_objects/memory_game.dart';
import 'package:test/test.dart';

const flip = FlipMemoryCard();

/// Две пары: карточки 0/1 — apple, 2/3 — book.
MemoryGame game() => MemoryGame(
  cards: const [
    MemoryCard(id: 0, pairId: 0, text: 'apple', isEnglish: true),
    MemoryCard(id: 1, pairId: 0, text: 'яблоко', isEnglish: false),
    MemoryCard(id: 2, pairId: 1, text: 'book', isEnglish: true),
    MemoryCard(id: 3, pairId: 1, text: 'книга', isEnglish: false),
  ],
);

MemoryCardState stateOf(MemoryGame state, int id) =>
    state.cards.firstWhere((card) => card.id == id).state;

void main() {
  test('should_flip_a_hidden_card', () {
    final next = flip(game(), 0);

    expect(stateOf(next, 0), MemoryCardState.flipped);
    expect(next.flippedCardIds, [0]);
  });

  test('should_not_flip_an_already_flipped_card', () {
    final once = flip(game(), 0);
    final twice = flip(once, 0);

    expect(twice, once);
  });

  test('should_not_flip_a_matched_card', () {
    final matched = flip(flip(game(), 0), 1);
    final again = flip(matched, 0);

    expect(again, matched);
  });

  test('should_match_pair_with_same_pair_id', () {
    final next = flip(flip(game(), 0), 1);

    expect(stateOf(next, 0), MemoryCardState.matched);
    expect(stateOf(next, 1), MemoryCardState.matched);
    expect(next.flippedCardIds, isEmpty);
    expect(next.pairsMatched, 1);
  });

  test('should_keep_both_flipped_when_pair_differs', () {
    final next = flip(flip(game(), 0), 2);

    expect(stateOf(next, 0), MemoryCardState.flipped);
    expect(stateOf(next, 2), MemoryCardState.flipped);
    expect(next.flippedCardIds, [0, 2]);
  });

  test('should_increment_moves_on_each_flip', () {
    final next = flip(flip(game(), 0), 2);

    expect(next.moves, 2);
  });

  test('should_win_when_every_pair_is_matched', () {
    final state = flip(flip(flip(flip(game(), 0), 1), 2), 3);

    expect(state.isWon, isTrue);
  });

  test('should_reset_flipped_cards_back_to_hidden', () {
    final mismatched = flip(flip(game(), 0), 2);
    final reset = flip.resetFlipped(mismatched);

    expect(stateOf(reset, 0), MemoryCardState.hidden);
    expect(reset.flippedCardIds, isEmpty);
    expect(reset.moves, 2, reason: 'ходы не откатываются');
  });
}
