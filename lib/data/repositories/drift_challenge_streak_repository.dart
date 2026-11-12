import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/challenge_streak_repository.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// `ChallengeStreakRepository` поверх Drift (ADR-032).
///
/// Строка одна (`CHECK (id = 1)`), поэтому `save` всегда пишет `id = 1`
/// через `insertOnConflictUpdate`. Время приходит из домена и только
/// проверяется здесь.
final class DriftChallengeStreakRepository
    implements ChallengeStreakRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftChallengeStreakRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ChallengeStreak?> get() async {
    final row = await (_db.select(
      _db.challengeStreaks,
    )..limit(1)).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final days = row.lastCompletedDateEpochDays;
    return ChallengeStreak(
      current: row.currentStreak,
      best: row.bestStreak,
      lastCompletedDate: days == null ? null : LocalDate(days),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtUtc,
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> save(ChallengeStreak streak) async {
    // Проверка дублирует контракт: в release assert вырезан, а локальное время
    // в БД испортило бы сравнения и экспорт.
    if (!streak.updatedAt.isUtc) {
      throw ArgumentError.value(streak.updatedAt, 'updatedAt', 'must be UTC');
    }
    await _db
        .into(_db.challengeStreaks)
        .insertOnConflictUpdate(
          ChallengeStreaksCompanion.insert(
            id: const Value(1),
            currentStreak: Value(streak.current),
            bestStreak: Value(streak.best),
            lastCompletedDateEpochDays: Value(
              streak.lastCompletedDate?.daysSinceEpoch,
            ),
            updatedAtUtc: streak.updatedAt.millisecondsSinceEpoch,
          ),
        );
  }
}
