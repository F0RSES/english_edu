import 'dart:convert';

import 'package:english_edu/data/export_payload_codec.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word({String? category, CefrLevel level = CefrLevel.a1}) => Word(
  id: const WordId(1),
  term: 'invoice',
  translation: 'счёт',
  category: category,
  level: level,
);

ExportPayload payloadOf({
  int schemaVersion = ExportPayload.currentSchemaVersion,
  Set<LocalDate> frozenDays = const <LocalDate>{},
  List<Word> words = const [],
  UserSettings? settings,
}) => ExportPayload(
  schemaVersion: schemaVersion,
  exportedAt: now,
  settings: settings ?? UserSettings.defaults(),
  words: words,
  progress: const [],
  logs: const [],
  stats: const [],
  frozenDays: frozenDays,
);

Map<String, Object?> firstWord(String json) {
  final root = jsonDecode(json) as Map<String, Object?>;
  return (root['words']! as List<Object?>).single! as Map<String, Object?>;
}

void main() {
  const codec = ExportPayloadCodec();

  test('currentSchemaVersion is 5', () {
    expect(ExportPayload.currentSchemaVersion, 5);
  });

  test('encode v3 includes word category', () {
    final json = codec.encode(payloadOf(words: [word(category: 'Бизнес')]));

    expect((jsonDecode(json) as Map<String, Object?>)['schemaVersion'], 5);
    expect(firstWord(json)['category'], 'Бизнес');
  });

  test('encode v2 leaves the category key out', () {
    final json = codec.encode(
      payloadOf(schemaVersion: 2, words: [word(category: 'Бизнес')]),
    );

    expect(firstWord(json).containsKey('category'), isFalse);
  });

  test('encode v3 includes frozenDays', () {
    final json = codec.encode(
      payloadOf(schemaVersion: 3, frozenDays: {const LocalDate(19723)}),
    );
    final root = jsonDecode(json) as Map<String, Object?>;

    expect(root['schemaVersion'], 3);
    expect(root['frozenDays'], [19723]);
  });

  test('decode v1 leaves frozenDays empty', () {
    final root = jsonDecode(
      codec.encode(payloadOf(schemaVersion: 1)),
    ) as Map<String, Object?>..remove('frozenDays');

    final decoded = codec.decode(jsonEncode(root));

    expect(decoded.schemaVersion, 1);
    expect(decoded.frozenDays, isEmpty);
  });

  test('decode v2 restores frozenDays', () {
    final decoded = codec.decode(
      codec.encode(
        payloadOf(schemaVersion: 2, frozenDays: {const LocalDate(19723)}),
      ),
    );

    expect(decoded.schemaVersion, 2);
    expect(decoded.frozenDays, {const LocalDate(19723)});
  });

  test('decode v2 leaves category null', () {
    // Снимок v3 с категорией, но заявленный как v2: категорию не читаем.
    final root = jsonDecode(
      codec.encode(payloadOf(words: [word(category: 'IT')])),
    ) as Map<String, Object?>;
    root['schemaVersion'] = 2;

    final decoded = codec.decode(jsonEncode(root));

    expect(decoded.words.single.category, isNull);
  });

  test('decode v3 restores category', () {
    final decoded = codec.decode(
      codec.encode(
        payloadOf(schemaVersion: 3, words: [word(category: 'Путешествия')]),
      ),
    );

    expect(decoded.schemaVersion, 3);
    expect(decoded.words.single.category, 'Путешествия');
  });

  test('encode v4 includes cefr level', () {
    final json = codec.encode(payloadOf(words: [word(level: CefrLevel.c1)]));

    expect(firstWord(json)['level'], 'C1');
  });

  test('encode v3 leaves the level key out', () {
    final json = codec.encode(
      payloadOf(schemaVersion: 3, words: [word(level: CefrLevel.c1)]),
    );

    expect(firstWord(json).containsKey('level'), isFalse);
  });

  test('decode v3 defaults all words to A1', () {
    final v3 = jsonDecode(
      codec.encode(payloadOf(schemaVersion: 3, words: [word()])),
    ) as Map<String, Object?>;
    final words = v3['words']! as List<Object?>;
    (words.single! as Map<String, Object?>)
      ..remove('level')
      ..['level'] = null;

    final decoded = codec.decode(jsonEncode(v3));

    expect(decoded.words.single.level, CefrLevel.a1);
  });

  test('decode v4 restores cefr level', () {
    final decoded = codec.decode(
      codec.encode(payloadOf(words: [word(level: CefrLevel.b2)])),
    );

    expect(decoded.words.single.level, CefrLevel.b2);
  });

  test('decode rejects an unknown cefr level', () {
    final root = jsonDecode(
      codec.encode(payloadOf(words: [word()])),
    ) as Map<String, Object?>;
    final words = root['words']! as List<Object?>;
    (words.single! as Map<String, Object?>)['level'] = 'D1';

    expect(() => codec.decode(jsonEncode(root)), throwsFormatException);
  });

  test('encode v5 includes preferredLevel', () {
    final json = codec.encode(
      payloadOf(
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.b1,
        ),
      ),
    );
    final settings =
        (jsonDecode(json) as Map<String, Object?>)['settings']!
            as Map<String, Object?>;

    expect(settings['preferredLevel'], 'B1');
  });

  test('encode v4 leaves the preferredLevel key out', () {
    final json = codec.encode(
      payloadOf(
        schemaVersion: 4,
        settings: UserSettings.defaults().copyWith(
          preferredLevel: CefrLevel.c1,
        ),
      ),
    );
    final settings =
        (jsonDecode(json) as Map<String, Object?>)['settings']!
            as Map<String, Object?>;

    expect(settings.containsKey('preferredLevel'), isFalse);
  });

  test('decode v4 defaults preferredLevel to A1', () {
    final decoded = codec.decode(codec.encode(payloadOf(schemaVersion: 4)));

    expect(decoded.settings.preferredLevel, CefrLevel.a1);
  });

  test('decode rejects an unknown preferredLevel', () {
    final root = jsonDecode(codec.encode(payloadOf())) as Map<String, Object?>;
    (root['settings']! as Map<String, Object?>)['preferredLevel'] = 'Z9';

    expect(() => codec.decode(jsonEncode(root)), throwsFormatException);
  });

  test('decode v5 restores preferredLevel', () {
    final decoded = codec.decode(
      codec.encode(
        payloadOf(
          settings: UserSettings.defaults().copyWith(
            preferredLevel: CefrLevel.b2,
          ),
        ),
      ),
    );

    expect(decoded.schemaVersion, 5);
    expect(decoded.settings.preferredLevel, CefrLevel.b2);
  });

  test('round-trips the current payload', () {
    final original = payloadOf(
      frozenDays: {const LocalDate(19723), const LocalDate(19724)},
      words: [word(category: 'Быт')],
    );

    expect(codec.decode(codec.encode(original)), equals(original));
  });

  test('invalid schemaVersion throws', () {
    final json = codec.encode(payloadOf(schemaVersion: 6));

    expect(() => codec.decode(json), throwsFormatException);
  });

  test('snapshot without frozenDays throws', () {
    final json = jsonDecode(codec.encode(payloadOf())) as Map<String, Object?>
      ..remove('frozenDays');

    expect(() => codec.decode(jsonEncode(json)), throwsFormatException);
  });
}
