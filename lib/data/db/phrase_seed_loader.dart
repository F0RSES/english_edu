import 'dart:convert';

import 'package:english_edu/domain/entities/phrase.dart';
import 'package:english_edu/domain/repositories/phrase_repository.dart';
import 'package:flutter/services.dart';

/// Путь к seed-файлу фраз.
const phraseSeedPath = 'assets/seed/phrases_v1.json';

/// Загружает фразы из ассетов в БД при первом обращении (ADR-038).
///
/// Идемпотентен: если таблица не пуста, ничего не делает. Загрузка ленивая —
/// её вызывает провайдер экрана, а не bootstrap: разговорник не нужен для
/// запуска и не должен задерживать старт.
final class PhraseSeedLoader {
  /// Создаёт загрузчик.
  const PhraseSeedLoader({
    required PhraseRepository phrases,
    required AssetBundle bundle,
  }) : _phrases = phrases,
       _bundle = bundle;

  final PhraseRepository _phrases;
  final AssetBundle _bundle;

  /// Загружает фразы, если их ещё нет; возвращает число загруженных.
  Future<int> load() async {
    if (await _phrases.count() > 0) {
      return 0;
    }

    final raw = await _bundle.loadString(phraseSeedPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?> || decoded['phrases'] is! List) {
      throw const FormatException('phrases_v1.json: ожидался объект с phrases');
    }

    final parsed = <Phrase>[];
    var id = 0;
    for (final item in decoded['phrases']! as List) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      parsed.add(
        Phrase(
          id: ++id,
          phrase: '${item['phrase']}',
          translation: '${item['translation']}',
          category: '${item['category']}',
          level: '${item['level'] ?? 'a1'}',
        ),
      );
    }

    await _phrases.insertMany(parsed);
    return parsed.length;
  }
}
