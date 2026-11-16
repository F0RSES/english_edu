import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/word_translation_repository.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';

/// `WordTranslationRepository` поверх Drift (BL-96, schema v20).
///
/// Время создания приходит из домена, репозиторий его только проверяет:
/// системное время в data-слое не читается.
final class DriftWordTranslationRepository
    implements WordTranslationRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftWordTranslationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<WordTranslation?> findByTerm(String term) async {
    final row =
        await (_db.select(_db.wordTranslations)
              ..where((t) => t.term.equals(term))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return WordTranslation(
      text: row.translation,
      partOfSpeech: row.partOfSpeech,
      transcription: row.transcription,
      example: row.example,
    );
  }

  @override
  Future<void> upsert(
    String term,
    WordTranslation translation, {
    required DateTime createdAtUtc,
  }) async {
    // В release assert вырезан, а не-UTC время в БД испортило бы порядок
    // и сравнения — проверяем явно (паттерн DriftWordHintRepository).
    if (!createdAtUtc.isUtc) {
      throw ArgumentError.value(createdAtUtc, 'createdAtUtc', 'must be UTC');
    }
    await _db
        .into(_db.wordTranslations)
        .insertOnConflictUpdate(
          WordTranslationsCompanion.insert(
            term: term,
            translation: translation.text,
            partOfSpeech: Value(translation.partOfSpeech),
            transcription: Value(translation.transcription),
            example: Value(translation.example),
            createdAtUtc: createdAtUtc.millisecondsSinceEpoch,
          ),
        );
  }
}
