import 'dart:convert';

import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/repositories/app_meta_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:flutter/services.dart';

/// Загружает seed-контент в пустую базу и обновляет устаревший (Phase 39c).
abstract interface class SeedLoader {
  /// Вставляет слова в пустую БД или обновляет устаревший seed.
  ///
  /// Возвращает число вставленных/обновлённых слов; 0 — всё актуально.
  Future<int> syncSeed();
}

/// Читает `assets/seed/words_v3.json` (7415 слов по уровням A0–C2,
/// тегированных категориями через `tools/tag_categories.dart`).
///
/// Пустая база заполняется целиком; непустая с устаревшей версией seed
/// обновляется upsert'ом по id (Phase 39c): категории/переводы приходят из
/// JSON, новые id добавляются, пользовательские слова (id вне seed-батча)
/// и прогресс SRS не трогаются. Версия хранится в `app_meta`, поэтому
/// обновление APK с новым seed доезжает до существующих установок.
/// Валидация JSON минимальная (`schemaVersion`); структурная проверка —
/// `tools/validate_seed.dart` (Phase 1.2a).
final class JsonSeedLoader implements SeedLoader {
  /// Создаёт загрузчик поверх репозиториев слов, метаданных и бандла ассетов.
  const JsonSeedLoader({
    required WordRepository words,
    required AssetBundle bundle,
    required AppMetaRepository meta,
  }) : _words = words,
       _bundle = bundle,
       _meta = meta;

  static const _assetPath = 'assets/seed/words_v3.json';

  /// Ключ версии seed-контента в `app_meta`.
  static const _seedVersionKey = 'seed_version';

  /// Версия контента: 1 — seed без категорий, 2 — тегированный v3 (Phase 39b).
  ///
  /// Поднимать при каждом изменении seed-файла, которое должно доехать
  /// до существующих установок.
  static const _seedVersion = '2';

  final WordRepository _words;
  final AssetBundle _bundle;
  final AppMetaRepository _meta;

  /// Загружает seed в пустую базу или обновляет устаревший (Phase 39c).
  ///
  /// Быстрый путь: база не пуста и версия в `app_meta` совпадает — 0,
  /// JSON не читается. Иначе батч вставляется (пустая база) или upsert'ится
  /// по id (устаревшая) в одной транзакции; версия пишется только после
  /// успеха, поэтому падение повторяется при следующем старте.
  @override
  Future<int> syncSeed() async {
    final existing = await _words.count();
    if (existing > 0 && await _meta.getValue(_seedVersionKey) == _seedVersion) {
      return 0;
    }

    final batch = await _readSeed();
    if (existing == 0) {
      await _words.insertMany(batch);
    } else {
      // Батч содержит только id из seed-файла: пользовательские слова
      // (id вне батча) и прогресс SRS остаются нетронутыми.
      await _words.upsertMany(batch);
    }
    await _meta.setValue(_seedVersionKey, _seedVersion);
    // Максимальный seed-id отличает seed-слова от кастомных при сбросе
    // прогресса (Phase 39e, UpdateWordStatus).
    var maxId = 0;
    for (final word in batch) {
      if (word.id.value > maxId) {
        maxId = word.id.value;
      }
    }
    await _meta.setValue(AppMetaRepository.seedMaxIdKey, '$maxId');
    return batch.length;
  }

  /// Читает и валидирует seed-файл, возвращая доменные слова.
  Future<List<domain.Word>> _readSeed() async {
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

    return [
      for (final item in words)
        if (item is Map<String, Object?>)
          _toDomain(item)
        else
          throw StateError('Seed word entry must be a JSON object'),
    ];
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
      // Ключ есть у всех статей v3; null — слово вне тем (Phase 39b).
      category: item['category'] as String?,
      level: _level(item),
      synonyms: _synonyms(item),
    );
  }

  /// Уровень слова из seed; без поля — A1 (ADR-023).
  ///
  /// seed v1 уровня не содержит, а переписывать контент в этой задаче нельзя:
  /// слова без метки получают A1 и остаются доступными новичку.
  CefrLevel _level(Map<String, Object?> item) {
    final raw = item['level'];
    if (raw == null) {
      return CefrLevel.a1;
    }
    if (raw is! String) {
      throw StateError('Seed word "level" must be a string');
    }
    // Сравнение вручную, а не CefrLevel.fromLabel: его ArgumentError — Error,
    // и перехватывать его ради сообщения об ошибке контента нельзя.
    for (final level in CefrLevel.values) {
      if (level.label.toLowerCase() == raw.toLowerCase()) {
        return level;
      }
    }
    throw StateError('Seed word has unknown level: $raw');
  }

  /// Синонимы слова: необязательное поле seed (Phase 36a).
  ///
  /// Старые seed-файлы поля не содержат — пустой список. Не-массив или
  /// не-строки — ошибка контента, как и у уровня.
  List<String> _synonyms(Map<String, Object?> item) {
    final raw = item['synonyms'];
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw StateError('Seed word "synonyms" must be an array');
    }
    final result = <String>[];
    for (final entry in raw) {
      if (entry is! String) {
        throw StateError('Seed word "synonyms" entries must be strings');
      }
      result.add(entry.trim());
    }
    return result;
  }
}
