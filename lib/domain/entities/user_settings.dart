import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:meta/meta.dart';

/// Marker used by nullable [UserSettings.copyWith] parameters to tell
/// "absent" from an explicit null (паттерн `Word.copyWith`): никнейм и
/// аватар можно очистить, остальные поля обнуляются только через дефолты.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}

String? _resolveText(Object? value, String? current) =>
    identical(value, _unset) ? current : value as String?;

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
    this.hasSeenOnboarding = false,
    this.preferredLevel = CefrLevel.a1,
    this.language = AppLanguage.ru,
    this.nickname,
    this.avatarPath,
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

  /// Пройден ли онбординг. `false` при первом запуске — экран показывается
  /// один раз (BL-61).
  final bool hasSeenOnboarding;

  /// Уровень пользователя по CEFR (ADR-023).
  ///
  /// По нему фильтруются новые слова в очереди дня: слова выше уровня в урок
  /// не попадают. Слова, которые пользователь уже начал учить, не фильтруются.
  final CefrLevel preferredLevel;

  /// Язык интерфейса (Phase 27b). Учебный контент не переводится.
  final AppLanguage language;

  /// Никнейм в профиле; null — fallback «Learner» (ADR-044).
  final String? nickname;

  /// Путь к файлу аватара в app documents; null — аватара нет (ADR-044).
  ///
  /// В БД и снимках хранится только путь: сам файл локальный и не
  /// переносится между устройствами.
  final String? avatarPath;

  /// Returns a copy with the given fields replaced.
  ///
  /// [nickname] и [avatarPath] очищаются явным null; остальные nullable
  /// поля сохраняют текущее значение при null.
  UserSettings copyWith({
    int? dailyNewLimit,
    int? dailyReviewLimit,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? ttsVoice,
    double? ttsSpeed,
    bool? hasSeenOnboarding,
    CefrLevel? preferredLevel,
    AppLanguage? language,
    Object? nickname = _unset,
    Object? avatarPath = _unset,
  }) => UserSettings(
    dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
    dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    ttsVoice: ttsVoice ?? this.ttsVoice,
    ttsSpeed: ttsSpeed ?? this.ttsSpeed,
    hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    preferredLevel: preferredLevel ?? this.preferredLevel,
    language: language ?? this.language,
    nickname: _resolveText(nickname, this.nickname),
    avatarPath: _resolveText(avatarPath, this.avatarPath),
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
          ttsSpeed == other.ttsSpeed &&
          hasSeenOnboarding == other.hasSeenOnboarding &&
          preferredLevel == other.preferredLevel &&
          language == other.language &&
          nickname == other.nickname &&
          avatarPath == other.avatarPath;

  @override
  int get hashCode => Object.hash(
    dailyNewLimit,
    dailyReviewLimit,
    remindersEnabled,
    reminderHour,
    reminderMinute,
    ttsVoice,
    ttsSpeed,
    hasSeenOnboarding,
    preferredLevel,
    language,
    nickname,
    avatarPath,
  );

  @override
  String toString() =>
      'UserSettings(new: $dailyNewLimit, '
      'review: $dailyReviewLimit, reminders: $remindersEnabled '
      'at $reminderHour:$reminderMinute, tts: $ttsVoice@$ttsSpeed, '
      'level: ${preferredLevel.label}, lang: ${language.code})';
}
