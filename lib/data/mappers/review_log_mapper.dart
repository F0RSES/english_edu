import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/card_state_mapper.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Domain `ReviewLog` ↔ Drift `ReviewLogRow`.
///
/// Два снимка `CardState` ложатся в колонки `prev*` и `new*`.
final class ReviewLogMapper {
  ReviewLogMapper._();

  /// Собирает запись журнала из строки БД.
  static ReviewLog toDomain(ReviewLogRow row) => ReviewLog(
        id: ReviewLogId(row.id),
        wordId: WordId(row.wordId),
        reviewedAt:
            DateTime.fromMillisecondsSinceEpoch(row.reviewedAtUtc, isUtc: true),
        grade: _gradeFrom(row.grade),
        previousCardState: CardStateMapper.fromColumns(
          easePermille: row.prevEasePermille,
          intervalDays: row.prevIntervalDays,
          repetitions: row.prevRepetitions,
          lapses: row.prevLapses,
          dueAtUtcMs: row.prevDueAtUtc,
        ),
        newCardState: CardStateMapper.fromColumns(
          easePermille: row.newEasePermille,
          intervalDays: row.newIntervalDays,
          repetitions: row.newRepetitions,
          lapses: row.newLapses,
          dueAtUtcMs: row.newDueAtUtc,
        ),
      );

  /// Раскладывает запись журнала в companion.
  static ReviewLogsCompanion toCompanion(ReviewLog log) {
    final prev = CardStateMapper.toColumns(log.previousCardState);
    final next = CardStateMapper.toColumns(log.newCardState);
    return ReviewLogsCompanion(
      id: Value(log.id.value),
      wordId: Value(log.wordId.value),
      reviewedAtUtc: Value(log.reviewedAt.toUtc().millisecondsSinceEpoch),
      grade: Value(log.grade.name),
      prevEasePermille: Value(prev.easePermille),
      prevIntervalDays: Value(prev.intervalDays),
      prevRepetitions: Value(prev.repetitions),
      prevLapses: Value(prev.lapses),
      prevDueAtUtc: Value(prev.dueAtUtcMs),
      newEasePermille: Value(next.easePermille),
      newIntervalDays: Value(next.intervalDays),
      newRepetitions: Value(next.repetitions),
      newLapses: Value(next.lapses),
      newDueAtUtc: Value(next.dueAtUtcMs),
    );
  }

  static ReviewGrade _gradeFrom(String name) {
    for (final grade in ReviewGrade.values) {
      if (grade.name == name) {
        return grade;
      }
    }
    throw StateError('Unknown ReviewGrade: $name');
  }
}
