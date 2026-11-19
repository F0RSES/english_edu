import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:english_edu/data/db/tables.dart';
import 'package:english_edu/domain/entities/chat_session.dart';

part 'app_database.g.dart';

/// Schema v23: сессии чата chat_sessions + chat_messages.session_id (Phase 42).
///
/// История: v2 — `frozen_days` (ADR-015), v3 — `words.category`,
/// v4 — `word_hints`, v5 — `user_settings.has_seen_onboarding` (BL-61),
/// v6 — `words.level` и `user_settings.preferred_level`,
/// v7 — `cloze_tasks`, v8 — `daily_challenges`, v9 — `challenge_streaks`,
/// v10 — `user_categories`, v11 — `achievements`, v12 — `typing_records`,
/// v13 — `phrases`, v14 — `stories`, v15 — `chat_messages`,
/// v16 — `cloze_tasks.options`, v17 — `user_settings.language`,
/// v18 — `user_settings.nickname` и `user_settings.avatar_path`,
/// v19 — очистка `cloze_tasks` (Phase 32: обновлён AI-промпт),
/// v20 — `word_translations` (Phase 33, BL-96),
/// v21 — `words.synonyms` (Phase 36a).
/// v22 — `app_meta` (Phase 39c).
/// v23 — `chat_sessions` и `chat_messages.session_id` (Phase 42, ADR-046).
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
    Stories,
    ChatSessions,
    ChatMessages,
    WordTranslations,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Открывает файловую базу приложения.
  AppDatabase() : super(_openConnection());

  /// Открывает переданное соединение — используется в тестах с in-memory.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 23) {
        await m.createTable(chatSessions);
        // chat_messages может ещё не существовать (from < 15): ниже она
        // создаётся сразу с текущей схемой. SQLite запрещает ADD COLUMN
        // NOT NULL без DEFAULT на непустой таблице, поэтому session_id
        // добавляется raw-ALTER как nullable и заполняется backfill'ом;
        // все insert'ы репозитория передают sessionId, NULL не появляется.
        // PRAGMA-guard — паттерн v16–v18 (addColumn не идемпотентен).
        final info = await customSelect("PRAGMA table_info('chat_messages')")
            .get();
        final hasSessionId = info.any(
          (row) => row.read<String>('name') == 'session_id',
        );
        if (info.isNotEmpty && !hasSessionId) {
          int? defaultSessionId;
          final stats = await customSelect(
            'SELECT COUNT(*) AS c, MIN(created_at_utc) AS min_ts, '
            'MAX(created_at_utc) AS max_ts FROM chat_messages',
          ).getSingle();
          if (stats.read<int>('c') > 0) {
            // Старые сообщения не должны потеряться: заводим дефолтную
            // сессию с заголовком из первого пользовательского сообщения.
            final firstUser = await customSelect(
              "SELECT content FROM chat_messages WHERE role = 'user' "
              'ORDER BY created_at_utc, id LIMIT 1',
            ).get();
            final content = firstUser.isNotEmpty
                ? firstUser.first.read<String>('content')
                : (await customSelect(
                    'SELECT content FROM chat_messages '
                    'ORDER BY created_at_utc, id LIMIT 1',
                  ).getSingle()).read<String>('content');
            defaultSessionId = await into(chatSessions).insert(
              ChatSessionsCompanion.insert(
                title: ChatSession.titleFromMessage(content),
                createdAtUtc: stats.read<int>('min_ts'),
                updatedAtUtc: stats.read<int>('max_ts'),
              ),
            );
          }
          await customStatement(
            'ALTER TABLE chat_messages ADD COLUMN session_id INTEGER '
            'REFERENCES chat_sessions (id) ON DELETE CASCADE',
          );
          if (defaultSessionId != null) {
            await customStatement('UPDATE chat_messages SET session_id = ?', [
              defaultSessionId,
            ]);
          }
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_chat_messages_session '
            'ON chat_messages (session_id)',
          );
        }
      }
      if (from < 22) {
        await m.createTable(appMeta);
      }
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
      if (from < 14) {
        await m.createTable(stories);
      }
      if (from < 15) {
        await m.createTable(chatMessages);
      }
      if (from < 16) {
        // addColumn не идемпотентен: createTable в ранних блоках создаёт
        // текущую схему (с options). Проверяем, чтобы не упасть на duplicate.
        final info = await customSelect("PRAGMA table_info('cloze_tasks')")
            .get();
        final hasOptions = info.any(
          (row) => row.read<String>('name') == 'options',
        );
        if (!hasOptions) {
          await m.addColumn(clozeTasks, clozeTasks.options);
        }
      }
      if (from < 17) {
        // addColumn не идемпотентен: тесты воссоздают старые схемы из
        // текущей, и language может уже существовать (паттерн v16/options).
        final info = await customSelect("PRAGMA table_info('user_settings')")
            .get();
        final hasLanguage = info.any(
          (row) => row.read<String>('name') == 'language',
        );
        if (!hasLanguage) {
          await m.addColumn(userSettingsTable, userSettingsTable.language);
        }
      }
      if (from < 18) {
        // addColumn не идемпотентен: тесты воссоздают старые схемы из
        // текущей, и колонки могут уже существовать (паттерн v16/v17).
        final info = await customSelect("PRAGMA table_info('user_settings')")
            .get();
        final columns = info.map((row) => row.read<String>('name')).toSet();
        if (!columns.contains('nickname')) {
          await m.addColumn(userSettingsTable, userSettingsTable.nickname);
        }
        if (!columns.contains('avatar_path')) {
          await m.addColumn(userSettingsTable, userSettingsTable.avatarPath);
        }
      }
      if (from < 19) {
        // AI-промпт обновлён: старые задания невалидны (все 5 вариантов
        // могли подходить по смыслу). Кэш расходный — перегенерируется
        // по запросу. delete — метод самой БД: у Migrator нет построчного
        // удаления, только deleteTable (DROP).
        await delete(clozeTasks).go();
      }
      if (from < 20) {
        await m.createTable(wordTranslations);
      }
      if (from < 21) {
        // addColumn не идемпотентен: тесты воссоздают старые схемы из
        // текущей, и synonyms может уже существовать (паттерн v16–v18).
        final info = await customSelect("PRAGMA table_info('words')").get();
        final hasSynonyms = info.any(
          (row) => row.read<String>('name') == 'synonyms',
        );
        if (!hasSynonyms) {
          await m.addColumn(words, words.synonyms);
        }
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
