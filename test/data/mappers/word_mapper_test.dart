import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/word_mapper.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('round-trips a word with every field through the database', () async {
    const word = domain.Word(
      id: WordId(7),
      term: 'hello',
      translation: 'привет',
      transcription: '/həˈləʊ/',
      partOfSpeech: 'noun',
      exampleSentence: 'Hello, world!',
      category: 'Быт',
    );

    await db.into(db.words).insert(WordMapper.toCompanion(word));
    final rows = await db.select(db.words).get();

    expect(rows, hasLength(1));
    expect(WordMapper.toDomain(rows.single), word);
  });

  test('keeps nullable fields null', () async {
    const word = domain.Word(id: WordId(1), term: 'book', translation: 'книга');

    await db.into(db.words).insert(WordMapper.toCompanion(word));
    final row = (await db.select(db.words).get()).single;

    expect(row.transcription, isNull);
    expect(row.partOfSpeech, isNull);
    expect(row.exampleSentence, isNull);
    expect(WordMapper.toDomain(row), word);
  });

  test('round-trip preserves category', () async {
    const word = domain.Word(
      id: WordId(3),
      term: 'invoice',
      translation: 'счёт',
      category: 'Бизнес',
    );

    await db.into(db.words).insert(WordMapper.toCompanion(word));
    final row = (await db.select(db.words).get()).single;

    expect(row.category, 'Бизнес');
    expect(WordMapper.toDomain(row).category, 'Бизнес');
  });

  test('category null round-trips', () async {
    const word = domain.Word(id: WordId(4), term: 'book', translation: 'книга');

    await db.into(db.words).insert(WordMapper.toCompanion(word));
    final row = (await db.select(db.words).get()).single;

    expect(row.category, isNull);
    expect(WordMapper.toDomain(row).category, isNull);
  });

  test('round-trip preserves cefr level', () async {
    const word = domain.Word(
      id: WordId(8),
      term: 'ubiquitous',
      translation: 'вездесущий',
      level: CefrLevel.c1,
    );

    await db.into(db.words).insert(WordMapper.toCompanion(word));
    final row = (await db.select(db.words).get()).single;

    expect(row.level, 'c1');
    expect(WordMapper.toDomain(row).level, CefrLevel.c1);
  });

  test('defaults to a1 for a row without an explicit level', () async {
    // Старая строка (schema v5) уровня не имела: колонка получила DEFAULT 'a1'.
    await db
        .into(db.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(9),
            term: 'book',
            translation: 'книга',
          ),
        );
    final row = (await db.select(db.words).get()).single;

    expect(row.level, 'a1');
    expect(WordMapper.toDomain(row).level, CefrLevel.a1);
  });

  test('keeps a single-letter term lower-case', () async {
    const word = domain.Word(id: WordId(10), term: 'i', translation: 'я');

    await db.into(db.words).insert(WordMapper.toCompanion(word));
    final row = (await db.select(db.words).get()).single;

    expect(row.term, 'i');
  });
}
