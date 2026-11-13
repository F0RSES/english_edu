import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:english_edu/data/db/tables.dart';

part 'app_database.g.dart';

/// Schema v1. Инициализация из `assets/seed/` — в 2a.2.
///
/// Миграции начинаются с v2: сейчас `onCreate` просто создаёт все таблицы.
@DriftDatabase(
  tables: [
    Words,
    WordProgresses,
    ReviewLogs,
    UserSettingsTable,
    DailyStatsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Открывает файловую базу приложения.
  AppDatabase() : super(_openConnection());

  /// Открывает переданное соединение — используется в тестах с in-memory.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // SQLite не проверяет внешние ключи, пока их не включат явно.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

QueryExecutor _openConnection() => driftDatabase(name: 'english_edu');
