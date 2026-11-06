import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/daily_challenge_repository.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// `DailyChallengeRepository` поверх Drift (ADR-030).
///
/// Время приходит из домена и только проверяется здесь: системные часы в
/// data-слое не читаются, иначе тесты стали бы недетерминированными.
final class DriftDailyChallengeRepository implements DailyChallengeRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftDailyChallengeRepository(this._db);

  final AppDatabase _db;

  @override
  Future<DailyChallenge?> getForDate(LocalDate date) async {
    final row =
        await (_db.select(_db.dailyChallenges)
              ..where((t) => t.dateEpochDays.equals(date.daysSinceEpoch))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return DailyChallenge(
      date: LocalDate(row.dateEpochDays),
      goalType: DailyChallengeType.fromName(row.goalType),
      goalValue: row.goalValue,
      progress: row.progress,
      completedAt: _toUtc(row.completedAtUtc),
      claimedAt: _toUtc(row.claimedAtUtc),
      xpReward: row.xpReward,
    );
  }

  @override
  Future<void> save(DailyChallenge challenge) async {
    // Проверка дублирует контракт: в release assert вырезан, а локальное время
    // в БД испортило бы сравнения и экспорт.
    _requireUtc(challenge.completedAt, 'completedAt');
    _requireUtc(challenge.claimedAt, 'claimedAt');
    await _db
        .into(_db.dailyChallenges)
        .insertOnConflictUpdate(
          DailyChallengesCompanion.insert(
            dateEpochDays: Value(challenge.date.daysSinceEpoch),
            goalType: challenge.goalType.name,
            goalValue: challenge.goalValue,
            progress: Value(challenge.progress),
            completedAtUtc: Value(
              challenge.completedAt?.millisecondsSinceEpoch,
            ),
            claimedAtUtc: Value(challenge.claimedAt?.millisecondsSinceEpoch),
            xpReward: challenge.xpReward,
          ),
        );
  }

  static DateTime? _toUtc(int? millis) => millis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

  static void _requireUtc(DateTime? value, String name) {
    if (value != null && !value.isUtc) {
      throw ArgumentError.value(value, name, 'must be UTC');
    }
  }
}
