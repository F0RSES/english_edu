import 'package:english_edu/domain/value_objects/memory_card.dart';
import 'package:meta/meta.dart';

/// Состояние партии «Memory» (ADR-036).
@immutable
final class MemoryGame {
  /// Создаёт партию с защитными копиями списков.
  ///
  /// Не `const`: списки копируются, иначе вызывающий мог бы менять состояние
  /// партии в обход `copyWith`.
  MemoryGame({
    required List<MemoryCard> cards,
    List<int> flippedCardIds = const [],
    this.moves = 0,
    this.isWon = false,
  }) : cards = List.unmodifiable(cards),
       flippedCardIds = List.unmodifiable(flippedCardIds);

  /// Все карточки в порядке показа.
  final List<MemoryCard> cards;

  /// Открытые карточки, максимум две.
  final List<int> flippedCardIds;

  /// Число ходов (каждое открытие).
  final int moves;

  /// Все пары найдены.
  final bool isWon;

  /// Сколько пар всего.
  int get pairsTotal => cards.length ~/ 2;

  /// Сколько пар уже найдено.
  int get pairsMatched =>
      cards.where((card) => card.state == MemoryCardState.matched).length ~/ 2;

  /// Returns a copy with the given fields replaced.
  MemoryGame copyWith({
    List<MemoryCard>? cards,
    List<int>? flippedCardIds,
    int? moves,
    bool? isWon,
  }) => MemoryGame(
    cards: cards ?? this.cards,
    flippedCardIds: flippedCardIds ?? this.flippedCardIds,
    moves: moves ?? this.moves,
    isWon: isWon ?? this.isWon,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryGame &&
          _sameCards(cards, other.cards) &&
          _sameIds(flippedCardIds, other.flippedCardIds) &&
          moves == other.moves &&
          isWon == other.isWon;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(cards),
    Object.hashAll(flippedCardIds),
    moves,
    isWon,
  );

  @override
  String toString() =>
      'MemoryGame(${cards.length} cards, moves: $moves, won: $isWon)';
}

bool _sameCards(List<MemoryCard> left, List<MemoryCard> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _sameIds(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
