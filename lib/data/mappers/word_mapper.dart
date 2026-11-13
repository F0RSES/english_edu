import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Domain `Word` ↔ Drift `Word`.
///
/// Поля `status` здесь нет: статус изучения живёт в `WordProgress` (ADR-004).
final class WordMapper {
  WordMapper._();

  /// Собирает доменную сущность из строки БД.
  static domain.Word toDomain(Word row) => domain.Word(
        id: WordId(row.id),
        term: row.term,
        translation: row.translation,
        transcription: row.transcription,
        partOfSpeech: row.partOfSpeech,
        exampleSentence: row.exampleSentence,
      );

  /// Раскладывает сущность в companion для insert/update.
  static WordsCompanion toCompanion(domain.Word word) => WordsCompanion(
        id: Value(word.id.value),
        term: Value(word.term),
        translation: Value(word.translation),
        transcription: Value(word.transcription),
        partOfSpeech: Value(word.partOfSpeech),
        exampleSentence: Value(word.exampleSentence),
      );
}
