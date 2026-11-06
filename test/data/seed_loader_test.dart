import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/data/seed_loader.dart';
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

  JsonSeedLoader loaderFor(AssetBundle bundle) =>
      JsonSeedLoader(words: words, bundle: bundle);

  test('loads 20 words into an empty database', () async {
    final loader = loaderFor(FileAssetBundle('assets/seed/words_v1.json'));

    expect(await loader.loadIfEmpty(), 20);
    expect(await words.getAll(), hasLength(20));
  });

  test('does not duplicate on a second call', () async {
    final loader = loaderFor(FileAssetBundle('assets/seed/words_v1.json'));

    expect(await loader.loadIfEmpty(), 20);
    expect(await loader.loadIfEmpty(), 0);
    expect(await words.getAll(), hasLength(20));
  });

  test('returns 0 when the table already has rows', () async {
    await loaderFor(FileAssetBundle('assets/seed/words_v1.json')).loadIfEmpty();

    final second = JsonSeedLoader(
      words: words,
      bundle: JsonAssetBundle(jsonEncode(seedJson(const [], version: 2))),
    );
    expect(await second.loadIfEmpty(), 0);
  });

  test('rolls the whole batch back when an insert fails', () async {
    // Одинаковый id: вставка второй строки падает, транзакция откатывается.
    final bundle = JsonAssetBundle(
      jsonEncode(seedJson([seedWord(1, 'one'), seedWord(1, 'uno')])),
    );

    await expectLater(
      loaderFor(bundle).loadIfEmpty(),
      throwsA(isA<Exception>()),
    );
    expect(await words.getAll(), isEmpty);
  });

  test('throws on an unsupported schema version', () async {
    final bundle = JsonAssetBundle(
      jsonEncode(seedJson([seedWord(1, 'one')], version: 2)),
    );

    await expectLater(
      loaderFor(bundle).loadIfEmpty(),
      throwsA(isA<StateError>()),
    );
  });

  test('maps seed fields into columns', () async {
    await loaderFor(FileAssetBundle('assets/seed/words_v1.json')).loadIfEmpty();

    final stored = await words.getAll();
    final first = stored.firstWhere((word) => word.id.value == 1);
    expect(first.term, 'the');
    expect(first.translation, 'определённый артикль');
    expect(first.transcription, '/ðə/');
    expect(first.partOfSpeech, 'article');
    expect(first.exampleSentence, 'The cat is on the mat.');
  });

  test('defaults a missing level to a1', () async {
    final bundle = JsonAssetBundle(jsonEncode(seedJson([seedWord(1, 'book')])));

    await loaderFor(bundle).loadIfEmpty();

    // seed v1 уровня не содержит: слово должно остаться доступным новичку.
    expect((await db.select(db.words).get()).single.level, 'a1');
  });

  test('keeps the level from the seed', () async {
    final entry = seedWord(1, 'ubiquitous')..['level'] = 'C1';
    final bundle = JsonAssetBundle(jsonEncode(seedJson([entry])));

    await loaderFor(bundle).loadIfEmpty();

    // В БД метка канонизируется в нижний регистр маппером.
    expect((await db.select(db.words).get()).single.level, 'c1');
  });

  test('throws on an unknown level', () async {
    final entry = seedWord(1, 'book')..['level'] = 'D1';
    final bundle = JsonAssetBundle(jsonEncode(seedJson([entry])));

    expect(loaderFor(bundle).loadIfEmpty(), throwsStateError);
  });
}
