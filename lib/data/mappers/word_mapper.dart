import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/value_objects/cefr_level.dart';
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
    category: row.category,
    level: CefrLevel.fromLabel(row.level),
    synonyms: _synonymsFrom(row.synonyms),
  );

  /// Раскладывает сущность в companion для insert/update.
  static WordsCompanion toCompanion(domain.Word word) => WordsCompanion(
    id: Value(word.id.value),
    term: Value(word.term),
    translation: Value(word.translation),
    transcription: Value(word.transcription),
    partOfSpeech: Value(word.partOfSpeech),
    exampleSentence: Value(word.exampleSentence),
    category: Value(word.category),
    // Метка пишется в нижнем регистре: DDL-дефолт 'a1' и данные не должны
    // расходиться регистром (CefrLevel.fromLabel читает оба).
    level: Value(word.level.label.toLowerCase()),
    synonyms: Value(word.synonyms.isEmpty ? null : jsonEncode(word.synonyms)),
  );

  /// Синонимы из JSON-строки; null или битый JSON — пустой список.
  ///
  /// Битый JSON возможен только при ручной правке БД: слово должно
  /// загрузиться, а не уронить словарь.
  static List<String> _synonymsFrom(String? raw) {
    if (raw == null) {
      return const [];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) {
      return const [];
    }
    return [
      for (final item in decoded)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
