import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/repositories/chat_repository.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';

/// `ChatRepository` поверх Drift (ADR-041).
///
/// Время создания приходит из домена (`ChatMessage.createdAtUtc`), репозиторий
/// его только проверяет: системное время в data-слое не читается.
final class DriftChatRepository implements ChatRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftChatRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ChatMessage>> getAll() async {
    final rows =
        await (_db.select(_db.chatMessages)..orderBy([
              (t) => OrderingTerm.asc(t.createdAtUtc),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<ChatMessage>> getLastN(int n) async {
    if (n <= 0) {
      throw ArgumentError.value(n, 'n', 'must be positive');
    }
    final rows =
        await (_db.select(_db.chatMessages)
              ..orderBy([
                (t) => OrderingTerm.desc(t.createdAtUtc),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(n))
            .get();
    // Разворот: последние N возвращаются в хронологическом порядке —
    // контекст для модели должен идти от старых к новым.
    return rows.reversed.map(_fromRow).toList();
  }

  @override
  Future<void> append(ChatMessage message) async {
    // Проверка дублирует валидацию entity: не-UTC время в БД испортило бы
    // порядок и сравнения.
    if (!message.createdAtUtc.isUtc) {
      throw ArgumentError.value(
        message.createdAtUtc,
        'createdAtUtc',
        'must be UTC',
      );
    }
    await _db
        .into(_db.chatMessages)
        .insert(
          ChatMessagesCompanion.insert(
            role: message.role.name,
            content: message.content,
            createdAtUtc: message.createdAtUtc.millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<void> clear() async {
    await _db.delete(_db.chatMessages).go();
  }

  ChatMessage _fromRow(ChatMessageRow row) => ChatMessage(
    id: row.id,
    role: ChatRole.values.byName(row.role),
    content: row.content,
    createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtc,
      isUtc: true,
    ),
  );
}
