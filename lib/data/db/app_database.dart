import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:english_edu/data/db/tables.dart';

part 'app_database.g.dart';

/// Schema v3: у слова появилась необязательная `category` (ADR-002 миграции).
///
/// История: v2 добавила `frozen_days` (ADR-015), v3 — колонку `words.category`.
/// `onCreate` создаёт всё сразу, `onUpgrade` только докатывает недостающее:
/// существующие таблицы и данные не пересоздаются.
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(frozenDays);
      }
      if (from < 3) {
        await m.addColumn(words, words.category);
      }
    },
    // SQLite не проверяет внешние ключи, пока их не включат явно.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() => driftDatabase(name: 'english_edu');
