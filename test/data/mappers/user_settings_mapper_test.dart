import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/user_settings_mapper.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:test/test.dart';

final updatedAt = DateTime.utc(2024, 5, 15, 12);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('round-trips default settings', () async {
    final settings = UserSettings.defaults();

    await db
        .into(db.userSettingsTable)
        .insert(UserSettingsMapper.toCompanion(settings, updatedAt: updatedAt));
    final row = (await db.select(db.userSettingsTable).get()).single;

    expect(UserSettingsMapper.toDomain(row), settings);
  });

  test('keeps every field and stores updatedAt as UTC ms', () async {
    final settings = UserSettings.defaults().copyWith(
      dailyNewLimit: 3,
      dailyReviewLimit: 7,
      remindersEnabled: true,
      reminderHour: 21,
      reminderMinute: 45,
      ttsVoice: 'en-GB',
      ttsSpeed: 0.55,
    );

    await db
        .into(db.userSettingsTable)
        .insert(UserSettingsMapper.toCompanion(settings, updatedAt: updatedAt));
    final row = (await db.select(db.userSettingsTable).get()).single;

    expect(row.id, 1);
    expect(row.updatedAtUtc, updatedAt.millisecondsSinceEpoch);
    expect(UserSettingsMapper.toDomain(row), settings);
  });

  test('round-trips the onboarding flag', () async {
    final settings = UserSettings.defaults().copyWith(hasSeenOnboarding: true);
    final updatedAt = DateTime.utc(2024, 5, 15, 12);

    await db
        .into(db.userSettingsTable)
        .insertOnConflictUpdate(
          UserSettingsMapper.toCompanion(settings, updatedAt: updatedAt),
        );
    final row = (await db.select(db.userSettingsTable).get()).single;

    expect(row.hasSeenOnboarding, isTrue);
    expect(UserSettingsMapper.toDomain(row).hasSeenOnboarding, isTrue);
  });

  test('keeps boundary ttsSpeed values', () async {
    for (final speed in [0.1, 1.0]) {
      final settings = UserSettings.defaults().copyWith(ttsSpeed: speed);
      final restored = UserSettingsMapper.toDomain(
        UserSettingsRow(
          id: 1,
          dailyNewLimit: settings.dailyNewLimit,
          dailyReviewLimit: settings.dailyReviewLimit,
          remindersEnabled: settings.remindersEnabled,
          reminderHour: settings.reminderHour,
          reminderMinute: settings.reminderMinute,
          ttsVoice: settings.ttsVoice,
          ttsSpeed: speed,
          hasSeenOnboarding: settings.hasSeenOnboarding,
          updatedAtUtc: 0,
        ),
      );
      expect(restored.ttsSpeed, speed);
    }
  });
}
