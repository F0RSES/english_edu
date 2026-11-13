import 'package:english_edu/domain/entities/chat_message.dart';

/// Локальная история чата с AI-помощником (ADR-041).
///
/// История хранится только на устройстве и не синхронизируется в облако.
abstract interface class ChatRepository {
  /// Возвращает последние [n] сообщений в хронологическом порядке
  /// (от старых к новым); [n] должен быть положительным.
  Future<List<ChatMessage>> getLastN(int n);

  /// Возвращает всю историю в хронологическом порядке.
  Future<List<ChatMessage>> getAll();

  /// Добавляет сообщение; id назначает БД (autoIncrement), переданный
  /// в [message] id игнорируется.
  Future<void> append(ChatMessage message);

  /// Удаляет всю историю сообщений.
  Future<void> clear();
}
