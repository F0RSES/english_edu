import 'dart:convert';

import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/repositories/story_repository.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:flutter/services.dart';

/// Путь к seed-файлу рассказов.
const storySeedPath = 'assets/seed/stories_v1.json';

/// Загружает рассказы из ассетов в БД при первом обращении (ADR-039).
///
/// Идемпотентен: если таблица не пуста, ничего не делает. Загрузка ленивая —
/// её вызывает провайдер экрана, а не bootstrap: чтение не нужно для запуска
/// и не должно задерживать старт.
final class StorySeedLoader {
  /// Создаёт загрузчик.
  const StorySeedLoader({
    required StoryRepository stories,
    required AssetBundle bundle,
  }) : _stories = stories,
       _bundle = bundle;

  final StoryRepository _stories;
  final AssetBundle _bundle;

  /// Загружает рассказы, если их ещё нет; возвращает число загруженных.
  Future<int> loadIfEmpty() async {
    if (await _stories.count() > 0) {
      return 0;
    }

    final raw = await _bundle.loadString(storySeedPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?> || decoded['stories'] is! List) {
      throw const FormatException('stories_v1.json: ожидался объект с stories');
    }

    final parsed = <Story>[];
    var id = 0;
    for (final item in decoded['stories']! as List) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      parsed.add(
        Story(
          id: ++id,
          title: '${item['title']}',
          text: '${item['text']}',
          translation: '${item['translation']}',
          level: CefrLevel.fromLabel('${item['level'] ?? 'a1'}'),
        ),
      );
    }

    await _stories.insertMany(parsed);
    return parsed.length;
  }
}
