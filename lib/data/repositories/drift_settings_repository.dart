import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/mappers/user_settings_mapper.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';

/// `SettingsRepository` поверх Drift.
///
/// Чтение ленивое: если строки нет, возвращаются дефолты и запись в БД не
/// создаётся. Сохранение — только явный [save].
final class DriftSettingsRepository implements SettingsRepository {
  /// Создаёт репозиторий поверх базы и внедрённых часов.
  const DriftSettingsRepository(this._db, {required DateTime Function() clock})
      : _clock = clock;

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<UserSettings> get() async {
    final row = await (_db.select(_db.userSettingsTable)
          ..where((t) => t.id.equals(1))
          ..limit(1))
        .getSingleOrNull();
    return row == null
        ? UserSettings.defaults()
        : UserSettingsMapper.toDomain(row);
  }

  @override
  Future<void> save(UserSettings settings) async {
    await _db.into(_db.userSettingsTable).insertOnConflictUpdate(
          UserSettingsMapper.toCompanion(
            settings,
            updatedAt: _clock().toUtc(),
          ),
        );
  }
}
