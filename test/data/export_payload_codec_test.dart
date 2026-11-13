import 'dart:convert';

import 'package:english_edu/data/export_payload_codec.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

ExportPayload payloadOf({
  int schemaVersion = ExportPayload.currentSchemaVersion,
  Set<LocalDate> frozenDays = const <LocalDate>{},
}) => ExportPayload(
  schemaVersion: schemaVersion,
  exportedAt: now,
  settings: UserSettings.defaults(),
  words: const [],
  progress: const [],
  logs: const [],
  stats: const [],
  frozenDays: frozenDays,
);

void main() {
  const codec = ExportPayloadCodec();

  test('encode v2 includes frozenDays', () {
    final json = codec.encode(payloadOf(frozenDays: {const LocalDate(19723)}));
    final map = jsonDecode(json) as Map<String, Object?>;

    expect(map['schemaVersion'], 2);
    expect(map['frozenDays'], [19723]);
  });

  test('decode v1 leaves frozenDays empty', () {
    // v1-снимок: поля frozenDays не было вовсе.
    final json = jsonDecode(
      codec.encode(payloadOf(schemaVersion: 1)),
    ) as Map<String, Object?>..remove('frozenDays');

    final decoded = codec.decode(jsonEncode(json));

    expect(decoded.schemaVersion, 1);
    expect(decoded.frozenDays, isEmpty);
  });

  test('decode v2 restores frozenDays', () {
    final decoded = codec.decode(
      codec.encode(payloadOf(frozenDays: {const LocalDate(19723)})),
    );

    expect(decoded.schemaVersion, 2);
    expect(decoded.frozenDays, {const LocalDate(19723)});
  });

  test('round-trips a v2 payload', () {
    final original = payloadOf(
      frozenDays: {const LocalDate(19723), const LocalDate(19724)},
    );

    expect(codec.decode(codec.encode(original)), equals(original));
  });

  test('invalid schemaVersion throws', () {
    final json = codec.encode(payloadOf(schemaVersion: 3));

    expect(() => codec.decode(json), throwsFormatException);
  });

  test('v2 without frozenDays throws', () {
    final json = jsonDecode(codec.encode(payloadOf())) as Map<String, Object?>
      ..remove('frozenDays');

    expect(() => codec.decode(jsonEncode(json)), throwsFormatException);
  });
}
