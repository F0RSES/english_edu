import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';

/// In-memory settings repository for use-case tests.
final class FakeSettingsRepository implements SettingsRepository {
  /// Creates a fake holding [initial], or the MVP defaults.
  FakeSettingsRepository([UserSettings? initial])
      : _settings = initial ?? UserSettings.defaults();

  UserSettings _settings;

  @override
  Future<UserSettings> get() async => _settings;

  @override
  Future<void> save(UserSettings settings) async {
    _settings = settings;
  }
}
