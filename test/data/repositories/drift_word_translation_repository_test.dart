import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_word_translation_repository.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

const full = WordTranslation(
  text: 'яблоко',
  partOfSpeech: 'noun',
  transcription: '/ˈæp.əl/',
  example: 'I eat an apple.',
);

void main() {
  late AppDatabase db;
  late DriftWordTranslationRepository translations;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    translations = DriftWordTranslationRepository(db);
  });
  tearDown(() => db.close());

  test('saves a translation and reads it back with every field', () async {
    await translations.upsert('apple', full, createdAtUtc: now);

    expect(await translations.findByTerm('apple'), full);
    final row = (await db.select(db.wordTranslations).get()).single;
    expect(row.createdAtUtc, now.millisecondsSinceEpoch);
  });

  test('keeps nullable fields null', () async {
    await translations.upsert(
      'apple',
      const WordTranslation(text: 'яблоко'),
      createdAtUtc: now,
    );

    final stored = await translations.findByTerm('apple');
    expect(stored!.partOfSpeech, isNull);
    expect(stored.transcription, isNull);
    expect(stored.example, isNull);
  });

  test('replaces the translation of the same term', () async {
    await translations.upsert(
      'apple',
      const WordTranslation(text: 'первый'),
      createdAtUtc: now,
    );
    await translations.upsert(
      'apple',
      const WordTranslation(text: 'второй'),
      createdAtUtc: now,
    );

    final rows = await db.select(db.wordTranslations).get();
    expect(rows, hasLength(1));
    expect(rows.single.translation, 'второй');
  });

  test('returns null for an unknown term', () async {
    expect(await translations.findByTerm('apple'), isNull);
  });

  test('rejects a non-UTC createdAtUtc', () async {
    await expectLater(
      translations.upsert(
        'apple',
        const WordTranslation(text: 'яблоко'),
        createdAtUtc: DateTime(2024, 5, 15, 12),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
