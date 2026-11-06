import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/user_settings.dart';

/// Domain `UserSettings` ↔ Drift `UserSettingsRow`.
///
/// `ttsSpeed` хранится как `real`: слайдер с шагом 0.05 даёт точные double.
/// Если появится drift equality на double — переход на permille в BL-30.
final class UserSettingsMapper {
  UserSettingsMapper._();

  /// Собирает настройки из строки БД.
  static UserSettings toDomain(UserSettingsRow row) => UserSettings(
    dailyNewLimit: row.dailyNewLimit,
    dailyReviewLimit: row.dailyReviewLimit,
    remindersEnabled: row.remindersEnabled,
    reminderHour: row.reminderHour,
    reminderMinute: row.reminderMinute,
    ttsVoice: row.ttsVoice,
    ttsSpeed: row.ttsSpeed,
    hasSeenOnboarding: row.hasSeenOnboarding,
  );

  /// Раскладывает настройки в companion.
  ///
  /// `id` всегда 1: синглтон обеспечен `CHECK (id = 1)` в схеме.
  /// [updatedAt] передаётся снаружи: маппер не читает системные часы, иначе
  /// тесты становились бы недетерминированными.
  static UserSettingsTableCompanion toCompanion(
    UserSettings settings, {
    required DateTime updatedAt,
  }) => UserSettingsTableCompanion(
    id: const Value(1),
    dailyNewLimit: Value(settings.dailyNewLimit),
    dailyReviewLimit: Value(settings.dailyReviewLimit),
    remindersEnabled: Value(settings.remindersEnabled),
    reminderHour: Value(settings.reminderHour),
    reminderMinute: Value(settings.reminderMinute),
    ttsVoice: Value(settings.ttsVoice),
    ttsSpeed: Value(settings.ttsSpeed),
    hasSeenOnboarding: Value(settings.hasSeenOnboarding),
    updatedAtUtc: Value(updatedAt.toUtc().millisecondsSinceEpoch),
  );
}
