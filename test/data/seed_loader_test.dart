import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_app_meta_repository.dart';
import 'package:english_edu/data/repositories/drift_progress_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/data/seed_loader.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/entities/word_progress.dart' as domain;
import 'package:english_edu/domain/repositories/app_meta_repository.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_category.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

/// Отдаёт содержимое файла как ассет: в тестах нет Flutter asset bundle.
final class FileAssetBundle extends AssetBundle {
  FileAssetBundle(this.path);

  final String path;

  @override
  Future<ByteData> load(String key) async {
    final bytes = File(path).readAsBytesSync();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// Отдаёт заранее подготовленный JSON.
final class JsonAssetBundle extends AssetBundle {
  JsonAssetBundle(this.json);

  final String json;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
}

/// Финальный словарь, который читает приложение (Phase 38f).
const _mergedSeedPath = 'assets/seed/words_v3.json';

/// Сколько слов в финальном словаре: 2071 базовых + 5344 новых.
///
/// Файл лежит в репозитории, поэтому число стабильно: точное значение ловит
/// случайную потерю контента при пересборке словаря.
const _mergedSeedWords = 7415;

Map<String, Object?> seedJson(List<Object?> words, {int version = 1}) => {
  'schemaVersion': version,
  'sources': const [],
  'words': words,
};

Map<String, Object?> seedWord(int id, String term) => {
  'id': id,
  'term': term,
  'translation': 'перевод$id',
};

void main() {
  late AppDatabase db;
  late DriftWordRepository words;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    words = DriftWordRepository(db);
  });
  tearDown(() => db.close());

  JsonSeedLoader loaderFor(AssetBundle bundle) => JsonSeedLoader(
    words: words,
    bundle: bundle,
    meta: DriftAppMetaRepository(db),
  );

  test('loads the whole merged seed into an empty database', () async {
    final loader = loaderFor(FileAssetBundle(_mergedSeedPath));

    expect(await loader.syncSeed(), _mergedSeedWords);
    expect(await words.getAll(), hasLength(_mergedSeedWords));
    expect(_mergedSeedWords, greaterThan(2000));
  });

  test('parses synonyms when present and defaults to empty', () async {
    final loader = loaderFor(
      JsonAssetBundle(
        jsonEncode(
          seedJson([
            {
              ...seedWord(1, 'meal'),
              'synonyms': ['food', 'repast'],
            },
            seedWord(2, 'book'),
          ]),
        ),
      ),
    );

    expect(await loader.syncSeed(), 2);
    final all = await words.getAll();
    expect(all.firstWhere((w) => w.term == 'meal').synonyms, [
      'food',
      'repast',
    ]);
    expect(all.firstWhere((w) => w.term == 'book').synonyms, isEmpty);
  });

  test('does not duplicate on a second call', () async {
    final loader = loaderFor(FileAssetBundle(_mergedSeedPath));

    expect(await loader.syncSeed(), _mergedSeedWords);
    expect(await loader.syncSeed(), 0);
    expect(await words.getAll(), hasLength(_mergedSeedWords));
  });

  test('returns 0 when the table already has rows', () async {
    await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed();

    final second = JsonSeedLoader(
      words: words,
      bundle: JsonAssetBundle(jsonEncode(seedJson(const [], version: 2))),
      meta: DriftAppMetaRepository(db),
    );
    expect(await second.syncSeed(), 0);
  });

  test('rolls the whole batch back when an insert fails', () async {
    // Одинаковый id: вставка второй строки падает, транзакция откатывается.
    final bundle = JsonAssetBundle(
      jsonEncode(seedJson([seedWord(1, 'one'), seedWord(1, 'uno')])),
    );

    await expectLater(loaderFor(bundle).syncSeed(), throwsA(isA<Exception>()));
    expect(await words.getAll(), isEmpty);
  });

  test('throws on an unsupported schema version', () async {
    final bundle = JsonAssetBundle(
      jsonEncode(seedJson([seedWord(1, 'one')], version: 2)),
    );

    await expectLater(loaderFor(bundle).syncSeed(), throwsA(isA<StateError>()));
  });

  test('loads words of every graded level from the merged seed', () async {
    await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed();

    final levels = {for (final word in await words.getAll()) word.level};

    // Words v3 размечен полностью: все семь уровней A0–C2 (Phase 38f).
    expect(
      levels,
      containsAll(<CefrLevel>[
        CefrLevel.a0,
        CefrLevel.a1,
        CefrLevel.a2,
        CefrLevel.b1,
        CefrLevel.b2,
        CefrLevel.c1,
        CefrLevel.c2,
      ]),
    );
  });

  test('maps seed fields into columns', () async {
    await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed();

    final stored = await words.getAll();
    final first = stored.firstWhere((word) => word.id.value == 1);
    expect(first.term, 'the');
    expect(first.translation, 'определённый артикль');
    expect(first.transcription, '/ðə/');
    expect(first.partOfSpeech, 'article');
    expect(first.exampleSentence, 'The cat is on the mat.');
  });

  test('seed words carry thematic categories (Phase 39b)', () async {
    await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed();

    final all = await words.getAll();
    final categorized = all.where((word) => word.category != null).length;
    // Точное число фиксирует контент: случайная потеря тегов ловится сразу.
    expect(categorized, 2323);
    expect(all.firstWhere((word) => word.term == 'apple').category, 'food');
  });

  test('defaults a missing level to a1', () async {
    final bundle = JsonAssetBundle(jsonEncode(seedJson([seedWord(1, 'book')])));

    await loaderFor(bundle).syncSeed();

    // seed v1 уровня не содержит: слово должно остаться доступным новичку.
    expect((await db.select(db.words).get()).single.level, 'a1');
  });

  test('keeps the level from the seed', () async {
    final entry = seedWord(1, 'ubiquitous')..['level'] = 'C1';
    final bundle = JsonAssetBundle(jsonEncode(seedJson([entry])));

    await loaderFor(bundle).syncSeed();

    // В БД метка канонизируется в нижний регистр маппером.
    expect((await db.select(db.words).get()).single.level, 'c1');
  });

  test('throws on an unknown level', () async {
    final entry = seedWord(1, 'book')..['level'] = 'D1';
    final bundle = JsonAssetBundle(jsonEncode(seedJson([entry])));

    expect(loaderFor(bundle).syncSeed(), throwsStateError);
  });

  test('maps raw JSON category through the filter (Phase 39c)', () async {
    final bundle = JsonAssetBundle(
      jsonEncode(
        seedJson([
          {...seedWord(1, 'apple'), 'category': 'food'},
          {...seedWord(2, 'banana'), 'category': 'Food'},
        ]),
      ),
    );

    await loaderFor(bundle).syncSeed();

    final all = await words.getAll();
    final apple = all.firstWhere((w) => w.term == 'apple');
    expect(apple.category, 'food');
    expect(
      WordCategory.food.matches(
        category: apple.category,
        partOfSpeech: apple.partOfSpeech,
      ),
      isTrue,
    );
    // Регистр не важен: matches нормализует строку.
    final banana = all.firstWhere((w) => w.term == 'banana');
    expect(WordCategory.food.matches(category: banana.category), isTrue);
  });

  test('reseed preserves user words and SRS progress (Phase 39c)', () async {
    final now = DateTime.utc(2024, 5, 15, 12);
    final progressRepo = DriftProgressRepository(db);
    // Устаревшая БД: apple без категории, пользовательское слово, прогресс.
    await words.insertMany([
      const domain.Word(id: WordId(29), term: 'apple', translation: 'яблоко'),
      const domain.Word(
        id: WordId(9000),
        term: 'myword',
        translation: 'моё слово',
      ),
    ]);
    await progressRepo.upsert(
      domain.WordProgress(
        wordId: const WordId(29),
        cardState: CardState(
          easePermille: 2500,
          intervalDays: 1,
          repetitions: 3,
          lapses: 0,
          dueAt: now,
        ),
        status: WordStatus.learning,
        firstSeenAt: now,
      ),
    );

    final loaded = await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed();

    expect(loaded, _mergedSeedWords);
    // Категория seed-слова обновилась из JSON.
    expect((await words.getById(const WordId(29)))!.category, 'food');
    // Пользовательское слово (id вне seed) на месте.
    expect((await words.getById(const WordId(9000)))!.term, 'myword');
    // Прогресс SRS не обнулился.
    final stored = await progressRepo.getByWordId(const WordId(29));
    expect(stored!.cardState.repetitions, 3);
    expect(stored.status, WordStatus.learning);
    // Повторный запуск — no-op: версия в app_meta совпадает.
    expect(await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed(), 0);
  });

  test('does not touch words when seed version is current', () async {
    final loader = loaderFor(FileAssetBundle(_mergedSeedPath));
    await loader.syncSeed();

    final original = await words.getById(const WordId(1));
    await words.upsert(original!.copyWith(translation: 'правка'));
    expect(await loader.syncSeed(), 0);
    expect((await words.getById(const WordId(1)))!.translation, 'правка');
  });

  test('records seed_max_id for custom-word detection (Phase 39e)', () async {
    await loaderFor(FileAssetBundle(_mergedSeedPath)).syncSeed();

    final meta = DriftAppMetaRepository(db);
    expect(await meta.getValue(AppMetaRepository.seedMaxIdKey), '7415');
  });
}
