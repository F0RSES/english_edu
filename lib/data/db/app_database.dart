import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:english_edu/data/db/tables.dart';

part 'app_database.g.dart';

/// Schema v2: добавлена `frozen_days` (ADR-015).
///
/// `onCreate` создаёт все таблицы, `onUpgrade` только добавляет новые:
/// существующие таблицы v1 не пересоздаются, данные переживают миграцию.
@DriftDatabase(
  tables: [
    Words,
    WordProgresses,
    ReviewLogs,
    UserSettingsTable,
    DailyStatsTable,
    FrozenDays,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Открывает файловую базу приложения.
  AppDatabase() : super(_openConnection());

  /// Открывает переданное соединение — используется в тестах с in-memory.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(frozenDays);
      }
    },
    // SQLite не проверяет внешние ключи, пока их не включат явно.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() => driftDatabase(name: 'english_edu');
