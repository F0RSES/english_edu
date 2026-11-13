import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tools/validate_seed_lib.dart';

Map<String, Object?> source({Object? id = 'manual-mvp'}) => {
  'id': id,
  'name': 'Manual MVP selection',
  'license': 'CC0',
  'url': null,
};

Map<String, Object?> word({
  Object? id = 1,
  Object? term = 'the',
  Object? translation = 'определённый артикль',
  Object? transcription = '/ðə/',
  Object? partOfSpeech = 'article',
  Object? exampleSentence = 'The cat is on the mat.',
  Object? sourceId = 'manual-mvp',
  Object? frequencyRank = 1,
  Object? autoTranslated,
}) {
  final result = <String, Object?>{
    'id': id,
    'term': term,
    'translation': translation,
    'transcription': transcription,
    'partOfSpeech': partOfSpeech,
    'exampleSentence': exampleSentence,
    'sourceId': sourceId,
    'frequencyRank': frequencyRank,
  };
  if (autoTranslated != null) {
    result['autoTranslated'] = autoTranslated;
  }
  return result;
}

Map<String, Object?> seed({
  Object? schemaVersion = 1,
  List<Object?>? sources,
  List<Object?>? words,
}) => {
  'schemaVersion': schemaVersion,
  'sources': sources ?? [source()],
  'words': words ?? [word()],
};

void main() {
  group('validateSeed', () {
    test('accepts the shipped seed file', () {
      final decoded = jsonDecode(
        File('assets/seed/words_v1.json').readAsStringSync(),
      );
      final result = validateSeed(decoded);

      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.wordCount, 20);
      expect(result.sourceCount, 1);
      expect(result.warnings, isEmpty);
    });

    test('rejects an unknown schema version', () {
      final result = validateSeed(seed(schemaVersion: 2));

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('schemaVersion'));
    });

    test('rejects a duplicate word id', () {
      final result = validateSeed(
        seed(
          words: [
            word(),
            word(term: 'be', frequencyRank: 2),
          ],
        ),
      );

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('duplicate'));
    });

    test('treats a duplicate term as a warning only', () {
      final result = validateSeed(
        seed(words: [word(), word(id: 2, frequencyRank: 2)]),
      );

      expect(result.isValid, isTrue);
      expect(result.warnings.single, contains('duplicate'));
    });

    test('rejects an empty term', () {
      final result = validateSeed(seed(words: [word(term: '  ')]));

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('term'));
    });

    test('rejects a sourceId that is not declared', () {
      final result = validateSeed(seed(words: [word(sourceId: 'missing')]));

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('sourceId'));
    });

    test('rejects a transcription without surrounding slashes', () {
      final result = validateSeed(seed(words: [word(transcription: 'ðə')]));

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('transcription'));
    });

    test('rejects a term that is not lower-case', () {
      final result = validateSeed(seed(words: [word(term: 'The')]));

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('lower-case'));
    });

    test('accepts an auto-translated word with a warning', () {
      final result = validateSeed(seed(words: [word(autoTranslated: true)]));

      expect(result.isValid, isTrue);
      expect(result.warnings.single, contains('autoTranslated'));
    });

    test('rejects a non-boolean autoTranslated', () {
      final result = validateSeed(seed(words: [word(autoTranslated: 'yes')]));

      expect(result.isValid, isFalse);
      expect(result.errors.single, contains('autoTranslated'));
    });

    test('allows the same rank across different sources', () {
      final result = validateSeed(
        seed(
          sources: [
            source(),
            source(id: 'ngsl-auto'),
          ],
          words: [
            word(),
            word(id: 2, term: 'be', sourceId: 'ngsl-auto'),
          ],
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.warnings, isEmpty);
    });

    test('treats duplicate ranks inside one source as informational', () {
      final result = validateSeed(
        seed(
          words: [
            word(),
            word(id: 2, term: 'be'),
          ],
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.warnings, isEmpty);
    });
  });
}
