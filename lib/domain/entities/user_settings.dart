import 'package:meta/meta.dart';

/// User preferences that drive the daily session and reminders.
@immutable
final class UserSettings {
  /// Creates settings with the MVP defaults.
  const UserSettings({
    this.dailyNewLimit = 10,
    this.dailyReviewLimit = 50,
    this.remindersEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.ttsVoice = 'en-US',
    this.ttsSpeed = 0.5,
  }) : assert(dailyNewLimit >= 0, 'dailyNewLimit must be >= 0'),
       assert(dailyReviewLimit >= 0, 'dailyReviewLimit must be >= 0'),
       assert(
         reminderHour >= 0 && reminderHour < 24,
         'reminderHour must be within 0..23',
       ),
       assert(
         reminderMinute >= 0 && reminderMinute < 60,
         'reminderMinute must be within 0..59',
       ),
       assert(
         ttsSpeed >= 0.1 && ttsSpeed <= 1.0,
         'ttsSpeed must be within 0.1..1.0',
       );

  /// Settings with every value at its MVP default.
  factory UserSettings.defaults() => const UserSettings();

  /// Maximum number of new words per day.
  final int dailyNewLimit;

  /// Maximum number of reviews per day.
  final int dailyReviewLimit;

  /// Whether local reminders are enabled.
  final bool remindersEnabled;

  /// Hour of the reminder, 0..23 in local time.
  final int reminderHour;

  /// Minute of the reminder, 0..59.
  final int reminderMinute;

  /// Voice identifier used by the TTS engine.
  final String ttsVoice;

  /// Speech rate, 0.1..1.0.
  final double ttsSpeed;

  /// Returns a copy with the given fields replaced.
  UserSettings copyWith({
    int? dailyNewLimit,
    int? dailyReviewLimit,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? ttsVoice,
    double? ttsSpeed,
  }) => UserSettings(
    dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
    dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    ttsVoice: ttsVoice ?? this.ttsVoice,
    ttsSpeed: ttsSpeed ?? this.ttsSpeed,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          dailyNewLimit == other.dailyNewLimit &&
          dailyReviewLimit == other.dailyReviewLimit &&
          remindersEnabled == other.remindersEnabled &&
          reminderHour == other.reminderHour &&
          reminderMinute == other.reminderMinute &&
          ttsVoice == other.ttsVoice &&
          ttsSpeed == other.ttsSpeed;

  @override
  int get hashCode => Object.hash(
    dailyNewLimit,
    dailyReviewLimit,
    remindersEnabled,
    reminderHour,
    reminderMinute,
    ttsVoice,
    ttsSpeed,
  );

  @override
  String toString() =>
      'UserSettings(new: $dailyNewLimit, '
      'review: $dailyReviewLimit, reminders: $remindersEnabled '
      'at $reminderHour:$reminderMinute, tts: $ttsVoice@$ttsSpeed)';
}
