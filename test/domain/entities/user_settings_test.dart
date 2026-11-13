import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:test/test.dart';

void main() {
  group('UserSettings', () {
    test('defaults carry the MVP values', () {
      final settings = UserSettings.defaults();
      expect(settings.dailyNewLimit, 10);
      expect(settings.dailyReviewLimit, 50);
      expect(settings.remindersEnabled, isFalse);
      expect(settings.reminderHour, 9);
      expect(settings.reminderMinute, 0);
      expect(settings.ttsVoice, 'en-US');
      expect(settings.ttsSpeed, 0.5);
    });

    test('rejects reminderHour outside 0..23', () {
      expect(
        () => UserSettings(reminderHour: 24),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UserSettings(reminderHour: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects reminderMinute outside 0..59', () {
      expect(
        () => UserSettings(reminderMinute: 60),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects ttsSpeed outside 0.1..1.0', () {
      expect(
        () => UserSettings(ttsSpeed: 0.05),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UserSettings(ttsSpeed: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative daily limits', () {
      expect(
        () => UserSettings(dailyNewLimit: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UserSettings(dailyReviewLimit: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts the boundary values', () {
      const edge = UserSettings(
        dailyNewLimit: 0,
        dailyReviewLimit: 0,
        reminderHour: 0,
        reminderMinute: 59,
        ttsSpeed: 1,
      );
      expect(edge.reminderHour, 0);
      expect(edge.reminderMinute, 59);
      expect(edge.ttsSpeed, 1);
      expect(const UserSettings(ttsSpeed: 0.1).ttsSpeed, 0.1);
    });

    test('copyWith replaces only the given fields', () {
      final updated = UserSettings.defaults().copyWith(
        remindersEnabled: true,
        reminderHour: 21,
      );
      expect(updated.remindersEnabled, isTrue);
      expect(updated.reminderHour, 21);
      expect(updated.dailyNewLimit, 10);
      expect(updated.ttsVoice, 'en-US');
    });

    test('is equal and has the same hash for equal fields', () {
      final a = UserSettings.defaults();
      const b = UserSettings();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when a single field differs', () {
      expect(
        UserSettings.defaults(),
        isNot(equals(UserSettings.defaults().copyWith(dailyNewLimit: 11))),
      );
    });
  });
}
