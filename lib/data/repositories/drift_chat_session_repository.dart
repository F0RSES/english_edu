import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/domain/repositories/chat_session_repository.dart';

/// `ChatSessionRepository` поверх Drift (ADR-046).
///
/// Время приходит из домена: системное время в data-слое не читается.
/// Каскадное удаление сообщений обеспечивает FK `chat_messages.session_id`
/// (PRAGMA foreign_keys включается в `beforeOpen`).
final class DriftChatSessionRepository implements ChatSessionRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftChatSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ChatSession>> getAll() async {
    final rows =
        await (_db.select(_db.chatSessions)..orderBy([
              (t) => OrderingTerm.desc(t.isPinned),
              (t) => OrderingTerm.desc(t.updatedAtUtc),
              (t) => OrderingTerm.desc(t.id),
            ]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ChatSession?> getMostRecent() async {
    final row =
        await (_db.select(_db.chatSessions)
              ..orderBy([
                (t) => OrderingTerm.desc(t.updatedAtUtc),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<ChatSession> create({
    required String title,
    required DateTime createdAtUtc,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (!createdAtUtc.isUtc) {
      throw ArgumentError.value(createdAtUtc, 'createdAtUtc', 'must be UTC');
    }
    final ms = createdAtUtc.millisecondsSinceEpoch;
    final id = await _db
        .into(_db.chatSessions)
        .insert(
          ChatSessionsCompanion.insert(
            title: trimmed,
            createdAtUtc: ms,
            updatedAtUtc: ms,
          ),
        );
    return ChatSession(
      id: id,
      title: trimmed,
      isPinned: false,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: createdAtUtc,
    );
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.chatSessions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> rename(int id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    // updatedAt не меняется: переименование не пересортировывает список.
    await (_db.update(_db.chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(title: Value(trimmed)),
    );
  }

  @override
  Future<void> togglePin(int id) async {
    final row = await (_db.select(
      _db.chatSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return;
    }
    // updatedAt не меняется: закрепление не пересортировывает список.
    await (_db.update(_db.chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(isPinned: Value(!row.isPinned)),
    );
  }

  @override
  Future<void> touch(int id, DateTime atUtc) async {
    if (!atUtc.isUtc) {
      throw ArgumentError.value(atUtc, 'atUtc', 'must be UTC');
    }
    await (_db.update(_db.chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(updatedAtUtc: Value(atUtc.millisecondsSinceEpoch)),
    );
  }

  ChatSession _fromRow(ChatSessionRow row) => ChatSession(
    id: row.id,
    title: row.title,
    isPinned: row.isPinned,
    createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtc,
      isUtc: true,
    ),
    updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.updatedAtUtc,
      isUtc: true,
    ),
  );
}
