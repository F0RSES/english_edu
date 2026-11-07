import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/phrase.dart';
import 'package:english_edu/domain/repositories/phrase_repository.dart';

/// `PhraseRepository` поверх Drift (ADR-038).
final class DriftPhraseRepository implements PhraseRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftPhraseRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Phrase>> getAll() async {
    final rows = await (_db.select(
      _db.phrases,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return [for (final row in rows) _toDomain(row)];
  }

  @override
  Future<List<Phrase>> getByCategory(String category) async {
    final rows = await (_db.select(_db.phrases)
          ..where((t) => t.category.equals(category))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return [for (final row in rows) _toDomain(row)];
  }

  @override
  Future<int> count() {
    final total = _db.phrases.id.count();
    return (_db.selectOnly(_db.phrases)..addColumns([total]))
        .getSingle()
        .then((row) => row.read(total) ?? 0);
  }

  @override
  Future<void> insertMany(Iterable<Phrase> phrases) async {
    await _db.transaction(() async {
      for (final phrase in phrases) {
        await _db
            .into(_db.phrases)
            .insert(
              PhrasesCompanion.insert(
                phrase: phrase.phrase,
                translation: phrase.translation,
                category: phrase.category,
                level: phrase.level,
                createdAtUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
      }
    });
  }

  Phrase _toDomain(PhraseRow row) => Phrase(
    id: row.id,
    phrase: row.phrase,
    translation: row.translation,
    category: row.category,
    level: row.level,
  );
}
