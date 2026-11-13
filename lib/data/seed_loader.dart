import 'dart:convert';

import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:flutter/services.dart';

/// Заполняет пустую базу словами из seed-файла.
abstract interface class SeedLoader {
  /// Вставляет слова, если база пуста, и возвращает число вставленных.
  Future<int> loadIfEmpty();
}

/// Читает `assets/seed/words_v1.json` при первом запуске.
///
/// Не перезаписывает существующие данные: если в `words` есть хотя бы одна
/// строка, возвращает 0. Валидация JSON минимальная (`schemaVersion`);
/// структурная проверка — `tools/validate_seed.dart` (Phase 1.2a).
final class JsonSeedLoader implements SeedLoader {
  /// Создаёт загрузчик поверх репозитория слов и бандла ассетов.
  const JsonSeedLoader({
    required WordRepository words,
    required AssetBundle bundle,
  }) : _words = words,
       _bundle = bundle;

  static const _assetPath = 'assets/seed/words_v1.json';

  final WordRepository _words;
  final AssetBundle _bundle;

  /// Атомарно вставляет слова, если таблица пуста.
  ///
  /// Вставка идёт через `WordRepository.insertMany` в одной транзакции:
  /// падение откатывает всё, и повторный запуск попробует снова. Если слова
  /// уже есть, возвращает 0 и ничего не трогает.
  @override
  Future<int> loadIfEmpty() async {
    final existing = await _words.count();
    if (existing > 0) {
      return 0;
    }

    final raw = await _bundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw StateError('Seed root must be a JSON object');
    }
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion != 1) {
      throw StateError('Unsupported seed schemaVersion: $schemaVersion');
    }
    final words = decoded['words'];
    if (words is! List) {
      throw StateError('Seed "words" must be an array');
    }

    final batch = [
      for (final item in words)
        if (item is Map<String, Object?>)
          _toDomain(item)
        else
          throw StateError('Seed word entry must be a JSON object'),
    ];
    await _words.insertMany(batch);
    return batch.length;
  }

  domain.Word _toDomain(Map<String, Object?> item) {
    final id = item['id'];
    final term = item['term'];
    final translation = item['translation'];
    if (id is! int || term is! String || translation is! String) {
      throw StateError('Seed word requires id, term and translation');
    }
    return domain.Word(
      id: WordId(id),
      term: term,
      translation: translation,
      transcription: item['transcription'] as String?,
      partOfSpeech: item['partOfSpeech'] as String?,
      exampleSentence: item['exampleSentence'] as String?,
    );
  }
}
