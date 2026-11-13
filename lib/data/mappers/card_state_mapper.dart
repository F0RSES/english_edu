import 'package:english_edu/domain/value_objects/card_state.dart';

/// Общий маппинг `CardState` для `WordProgress` и `ReviewLog`.
///
/// `dueAt` всегда UTC: в колонках лежат миллисекунды с эпохи, при чтении
/// восстанавливается UTC-момент (BL-20).
final class CardStateMapper {
  CardStateMapper._();

  /// Собирает VO из набора колонок.
  static CardState fromColumns({
    required int easePermille,
    required int intervalDays,
    required int repetitions,
    required int lapses,
    required int dueAtUtcMs,
  }) =>
      CardState(
        easePermille: easePermille,
        intervalDays: intervalDays,
        repetitions: repetitions,
        lapses: lapses,
        dueAt: DateTime.fromMillisecondsSinceEpoch(dueAtUtcMs, isUtc: true),
      );

  /// Раскладывает VO на колонки.
  static ({
    int easePermille,
    int intervalDays,
    int repetitions,
    int lapses,
    int dueAtUtcMs,
  }) toColumns(CardState state) =>
      (
        easePermille: state.easePermille,
        intervalDays: state.intervalDays,
        repetitions: state.repetitions,
        lapses: state.lapses,
        dueAtUtcMs: state.dueAt.toUtc().millisecondsSinceEpoch,
      );
}
