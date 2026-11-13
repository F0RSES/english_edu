import 'package:english_edu/data/mappers/card_state_mapper.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:test/test.dart';

void main() {
  final dueAt = DateTime.utc(2024, 5, 15, 12);

  test('round-trips a card state through columns', () {
    final state = CardState(
      easePermille: 2500,
      intervalDays: 15,
      repetitions: 3,
      lapses: 1,
      dueAt: dueAt,
    );

    final columns = CardStateMapper.toColumns(state);
    final restored = CardStateMapper.fromColumns(
      easePermille: columns.easePermille,
      intervalDays: columns.intervalDays,
      repetitions: columns.repetitions,
      lapses: columns.lapses,
      dueAtUtcMs: columns.dueAtUtcMs,
    );

    expect(restored, state);
  });

  test('stores dueAt as UTC milliseconds and restores UTC', () {
    final columns = CardStateMapper.toColumns(
      CardState.initial(dueAt),
    );

    expect(columns.dueAtUtcMs, dueAt.millisecondsSinceEpoch);

    final restored = CardStateMapper.fromColumns(
      easePermille: columns.easePermille,
      intervalDays: columns.intervalDays,
      repetitions: columns.repetitions,
      lapses: columns.lapses,
      dueAtUtcMs: columns.dueAtUtcMs,
    );
    expect(restored.dueAt.isUtc, isTrue);
    expect(restored.dueAt, dueAt);
  });

  test('converts a local dueAt to UTC before storing', () {
    final local = DateTime(2024, 5, 15, 12);
    final columns = CardStateMapper.toColumns(
      CardState.initial(local),
    );
    expect(columns.dueAtUtcMs, local.toUtc().millisecondsSinceEpoch);
  });
}
