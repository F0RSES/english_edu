import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/repositories/story_repository.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';

/// `StoryRepository` поверх Drift (ADR-039).
final class DriftStoryRepository implements StoryRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftStoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Story>> getAll() async {
    final rows = await (_db.select(
      _db.stories,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return [for (final row in rows) _toDomain(row)];
  }

  @override
  Future<List<Story>> getByLevel(CefrLevel level) async {
    final rows =
        await (_db.select(_db.stories)
              ..where((t) => t.level.equals(level.label.toLowerCase()))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return [for (final row in rows) _toDomain(row)];
  }

  @override
  Future<int> count() {
    final total = _db.stories.id.count();
    return (_db.selectOnly(
      _db.stories,
    )..addColumns([total])).getSingle().then((row) => row.read(total) ?? 0);
  }

  @override
  Future<void> insertMany(Iterable<Story> stories) async {
    await _db.transaction(() async {
      for (final story in stories) {
        await _db
            .into(_db.stories)
            .insert(
              StoriesCompanion.insert(
                title: story.title,
                content: story.text,
                translation: story.translation,
                level: story.level.label.toLowerCase(),
                createdAtUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
      }
    });
  }

  Story _toDomain(StoryRow row) => Story(
    id: row.id,
    title: row.title,
    text: row.content,
    translation: row.translation,
    level: CefrLevel.fromLabel(row.level),
  );
}
