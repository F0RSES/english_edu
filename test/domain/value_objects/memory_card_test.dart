import 'package:english_edu/domain/value_objects/memory_card.dart';
import 'package:test/test.dart';

MemoryCard card({MemoryCardState state = MemoryCardState.hidden}) =>
    MemoryCard(
      id: 1,
      pairId: 0,
      text: 'apple',
      isEnglish: true,
      state: state,
    );

void main() {
  test('should_copy_with_new_state', () {
    final flipped = card().copyWith(state: MemoryCardState.flipped);

    expect(flipped.state, MemoryCardState.flipped);
    expect(flipped.id, 1);
    expect(flipped.text, 'apple');
  });

  test('should_be_equal_when_all_fields_match', () {
    expect(card(), card());
    expect(card().hashCode, card().hashCode);
    expect(
      card(),
      isNot(card(state: MemoryCardState.matched)),
    );
  });
}
