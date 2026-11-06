import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/user_category_repository.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';

/// `UserCategoryRepository` поверх Drift (ADR-034).
///
/// Время создания пишется здесь из инжектированных часов: data-слой системные
/// часы не читает, иначе тесты стали бы недетерминированными.
final class DriftUserCategoryRepository implements UserCategoryRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftUserCategoryRepository(
    this._db, {
    required DateTime Function() clock,
  }) : _clock = clock;

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<List<UserCategory>> getAll() async {
    final rows = await (_db.select(
      _db.userCategories,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return [for (final row in rows) _toDomain(row)];
  }

  /// Сравнение в Dart, а не в SQL: `UNIQUE` в SQLite регистрозависим, а
  /// «Бизнес» и «бизнес» для пользователя одна категория. Таблица маленькая.
  @override
  Future<UserCategory?> findByName(String name) async {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) {
      return null;
    }
    final all = await getAll();
    for (final category in all) {
      if (category.name.trim().toLowerCase() == needle) {
        return category;
      }
    }
    return null;
  }

  @override
  Future<UserCategory> create(String name, {String? colorHex}) async {
    final now = _clock().toUtc();
    final id = await _db
        .into(_db.userCategories)
        .insert(
          UserCategoriesCompanion.insert(
            name: name,
            createdAtUtc: now.millisecondsSinceEpoch,
            colorHex: Value(colorHex),
          ),
        );
    return UserCategory(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAtUtc: now,
    );
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.userCategories)..where((t) => t.id.equals(id))).go();
  }

  UserCategory _toDomain(UserCategoryRow row) => UserCategory(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtc,
      isUtc: true,
    ),
  );
}
