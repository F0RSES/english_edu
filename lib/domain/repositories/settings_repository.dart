import 'package:english_edu/domain/entities/user_settings.dart';

/// Read and write access to user settings.
abstract interface class SettingsRepository {
  /// Returns the stored settings, or the MVP defaults when none are saved.
  Future<UserSettings> get();

  /// Replaces the stored settings with [settings].
  Future<void> save(UserSettings settings);
}
