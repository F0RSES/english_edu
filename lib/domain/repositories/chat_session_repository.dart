import 'package:english_edu/domain/entities/chat_session.dart';

/// Хранилище сессий чата с AI-помощником (Phase 42, ADR-046).
///
/// Сессии локальны, как и сообщения: в облако не синхронизируются
/// и в export-снимок не входят (приватность, ADR-041).
abstract interface class ChatSessionRepository {
  /// Все сессии: сначала закреплённые, затем по [ChatSession.updatedAtUtc]
  /// убыванию (свежие выше).
  Future<List<ChatSession>> getAll();

  /// Самая свежая по [ChatSession.updatedAtUtc] сессия; null — сессий нет.
  /// Закрепление не влияет: восстанавливается последний активный диалог.
  Future<ChatSession?> getMostRecent();

  /// Создаёт сессию с [title]; id назначает БД (autoIncrement).
  /// [createdAtUtc] должен быть в UTC; пустой title — [ArgumentError].
  Future<ChatSession> create({
    required String title,
    required DateTime createdAtUtc,
  });

  /// Удаляет сессию; её сообщения удаляются каскадом.
  Future<void> delete(int id);

  /// Переименовывает сессию, не меняя updatedAt.
  /// Пустой title — [ArgumentError].
  Future<void> rename(int id, String title);

  /// Переключает закрепление, не меняя updatedAt.
  Future<void> togglePin(int id);

  /// Обновляет updatedAt до [atUtc] (новое сообщение); [atUtc] — в UTC.
  Future<void> touch(int id, DateTime atUtc);
}
