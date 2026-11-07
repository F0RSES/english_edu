import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:english_edu/data/db/tables.dart';

part 'app_database.g.dart';

/// Schema v13: разговорник (ADR-038).
///
/// История: v2 — `frozen_days` (ADR-015), v3 — `words.category`,
/// v4 — `word_hints`, v5 — `user_settings.has_seen_onboarding` (BL-61),
/// v6 — `words.level` и `user_settings.preferred_level`,
/// v7 — `cloze_tasks`, v8 — `daily_challenges`, v9 — `challenge_streaks`,
/// v10 — `user_categories`, v11 — `achievements`, v12 — `typing_records`,
/// v13 — `phrases`.
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
    WordHints,
    ClozeTasks,
    DailyChallenges,
    ChallengeStreaks,
    UserCategories,
    Achievements,
    TypingRecords,
    Phrases,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Открывает файловую базу приложения.
  AppDatabase() : super(_openConnection());

  /// Открывает переданное соединение — используется в тестах с in-memory.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 13;

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
      if (from < 4) {
        await m.createTable(wordHints);
      }
      if (from < 5) {
        await m.addColumn(
          userSettingsTable,
          userSettingsTable.hasSeenOnboarding,
        );
      }
      if (from < 6) {
        // DEFAULT 'a1' в DDL: старые строки получают A1, а не NULL.
        await m.addColumn(words, words.level);
        await m.addColumn(userSettingsTable, userSettingsTable.preferredLevel);
      }
      if (from < 7) {
        await m.createTable(clozeTasks);
      }
      if (from < 8) {
        await m.createTable(dailyChallenges);
      }
      if (from < 9) {
        await m.createTable(challengeStreaks);
      }
      if (from < 13) {
        await m.createTable(phrases);
      }
      if (from < 12) {
        await m.createTable(typingRecords);
      }
      if (from < 11) {
        await m.createTable(achievements);
      }
      if (from < 10) {
        await m.createTable(userCategories);
        // Четыре базовые категории существуют у всех пользователей с v3:
        // без них слова с `Words.category` остались бы без чипа в фильтре.
        // id приходят из autoIncrement, поэтому защита «не удалять базовые»
        // опирается на порядок вставки (1..4).
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await customStatement(
          'INSERT INTO user_categories (name, color_hex, created_at_utc) '
          "VALUES ('Бизнес', '#FF5722', $now), "
          "('IT', '#2196F3', $now), "
          "('Путешествия', '#4CAF50', $now), "
          "('Быт', '#FFC107', $now)",
        );
      }
    },
    // SQLite не проверяет внешние ключи, пока их не включат явно.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() => driftDatabase(name: 'english_edu');
