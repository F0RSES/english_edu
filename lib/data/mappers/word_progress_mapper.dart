import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/card_state_mapper.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Domain `WordProgress` ↔ Drift `WordProgressRow`.
final class WordProgressMapper {
  WordProgressMapper._();

  /// Собирает доменную запись из строки БД.
  static WordProgress toDomain(WordProgressRow row) => WordProgress(
    wordId: WordId(row.wordId),
    cardState: CardStateMapper.fromColumns(
      easePermille: row.easePermille,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
      lapses: row.lapses,
      dueAtUtcMs: row.dueAtUtc,
    ),
    status: _statusFrom(row.status),
    firstSeenAt: DateTime.fromMillisecondsSinceEpoch(
      row.firstSeenAtUtc,
      isUtc: true,
    ),
    lastReviewedAt: row.lastReviewedAtUtc == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            row.lastReviewedAtUtc!,
            isUtc: true,
          ),
  );

  /// Раскладывает запись в companion для insert/update.
  static WordProgressesCompanion toCompanion(WordProgress progress) {
    final card = CardStateMapper.toColumns(progress.cardState);
    return WordProgressesCompanion(
      wordId: Value(progress.wordId.value),
      easePermille: Value(card.easePermille),
      intervalDays: Value(card.intervalDays),
      repetitions: Value(card.repetitions),
      lapses: Value(card.lapses),
      dueAtUtc: Value(card.dueAtUtcMs),
      status: Value(progress.status.name),
      firstSeenAtUtc: Value(
        progress.firstSeenAt.toUtc().millisecondsSinceEpoch,
      ),
      lastReviewedAtUtc: Value(
        progress.lastReviewedAt?.toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  static WordStatus _statusFrom(String name) {
    for (final status in WordStatus.values) {
      if (status.name == name) {
        return status;
      }
    }
    throw StateError('Unknown WordStatus: $name');
  }
}
