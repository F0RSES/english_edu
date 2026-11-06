import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/achievement_repository.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';

/// `AchievementRepository` поверх Drift (ADR-035).
///
/// Ключ строки — `AchievementType.key`; неизвестные ключи (достижение убрали
/// из кода) пропускаются при чтении, а не роняют экран.
final class DriftAchievementRepository implements AchievementRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftAchievementRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Achievement>> getAll() async {
    final rows = await _db.select(_db.achievements).get();
    return [
      for (final row in rows)
        if (_toDomain(row) case final achievement?) achievement,
    ];
  }

  @override
  Future<Achievement?> getByType(AchievementType type) async {
    final row =
        await (_db.select(_db.achievements)
              ..where((t) => t.id.equals(type.key))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(Achievement achievement) async {
    if (!achievement.lastUpdatedAt.isUtc) {
      throw ArgumentError.value(
        achievement.lastUpdatedAt,
        'lastUpdatedAt',
        'must be UTC',
      );
    }
    await _db
        .into(_db.achievements)
        .insertOnConflictUpdate(
          AchievementsCompanion.insert(
            id: achievement.type.key,
            progress: Value(achievement.progress),
            lastUpdatedAtUtc:
                achievement.lastUpdatedAt.millisecondsSinceEpoch,
            unlockedAtUtc: Value(
              achievement.unlockedAt?.millisecondsSinceEpoch,
            ),
          ),
        );
  }

  Achievement? _toDomain(AchievementRow row) {
    final type = AchievementType.fromKey(row.id);
    if (type == null) {
      return null;
    }
    final unlocked = row.unlockedAtUtc;
    return Achievement(
      type: type,
      progress: row.progress,
      unlockedAt: unlocked == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(unlocked, isUtc: true),
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.lastUpdatedAtUtc,
        isUtc: true,
      ),
    );
  }
}
