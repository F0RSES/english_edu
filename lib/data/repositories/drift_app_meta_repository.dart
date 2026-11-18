import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/app_meta_repository.dart';

/// `AppMetaRepository` поверх Drift (Phase 39c).
final class DriftAppMetaRepository implements AppMetaRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftAppMetaRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String?> getValue(String key) async {
    final row =
        await (_db.select(_db.appMeta)
              ..where((t) => t.key.equals(key))
              ..limit(1))
            .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setValue(String key, String value) async {
    await _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion(key: Value(key), value: Value(value)),
        );
  }
}
