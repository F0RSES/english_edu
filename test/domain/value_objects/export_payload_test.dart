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
  group('ExportPayload', () {
    test('v2 includes frozenDays', () {
      final payload = payloadOf(
        frozenDays: {const LocalDate(19723), const LocalDate(19724)},
      );

      expect(payload.frozenDays, {
        const LocalDate(19723),
        const LocalDate(19724),
      });
    });

    test('v1 has empty frozenDays', () {
      final payload = payloadOf(schemaVersion: 1);

      expect(payload.frozenDays, isEmpty);
      expect(payload.schemaVersion, 1);
    });

    test('currentSchemaVersion is 5', () {
      expect(ExportPayload.currentSchemaVersion, 5);
    });

    test('is equal when frozenDays match regardless of order', () {
      final a = payloadOf(frozenDays: {const LocalDate(1), const LocalDate(2)});
      final b = payloadOf(frozenDays: {const LocalDate(2), const LocalDate(1)});

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when frozenDays differ', () {
      final withFreeze = payloadOf(frozenDays: {const LocalDate(1)});
      final withoutFreeze = payloadOf();

      expect(withFreeze, isNot(equals(withoutFreeze)));
    });

    test('exposes frozenDays as an unmodifiable set', () {
      final payload = payloadOf(frozenDays: {const LocalDate(1)});

      expect(
        () => payload.frozenDays.add(const LocalDate(2)),
        throwsUnsupportedError,
      );
    });
  });
}
