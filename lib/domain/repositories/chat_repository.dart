import 'package:english_edu/domain/entities/chat_message.dart';

/// Локальная история чата с AI-помощником (ADR-041, ADR-046).
///
/// История хранится только на устройстве и не синхронизируется в облако.
/// Сообщения группируются по сессиям; глобальный [getAll] нужен достижениям
/// (счётчик сообщений не зависит от разбиения на диалоги).
abstract interface class ChatRepository {
  /// Возвращает последние [n] сообщений сессии [sessionId] в хронологическом
  /// порядке (от старых к новым); [n] должен быть положительным.
  Future<List<ChatMessage>> getLastN(int n, {required int sessionId});

  /// Возвращает всю историю всех сессий в хронологическом порядке.
  Future<List<ChatMessage>> getAll();

  /// Возвращает все сообщения сессии [sessionId] в хронологическом порядке.
  Future<List<ChatMessage>> getBySession(int sessionId);

  /// Добавляет сообщение в его сессию; id назначает БД (autoIncrement),
  /// переданный в [message] id игнорируется.
  Future<void> append(ChatMessage message);

  /// Удаляет все сообщения сессии [sessionId].
  Future<void> clear(int sessionId);
}
