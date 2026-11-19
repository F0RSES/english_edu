import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Одно сообщение чата с AI-помощником (ADR-041, ADR-046).
///
/// История хранится только на устройстве; сообщение принадлежит сессии
/// ([sessionId]), очистка — через `ChatRepository.clear(sessionId)`,
/// отдельных правок сообщений нет.
@immutable
final class ChatMessage {
  /// Создаёт сообщение; [createdAtUtc] должен быть в UTC.
  ///
  /// Не `const`: время проверяется в runtime, потому что assert вырезается
  /// в release-сборке (паттерн `ReviewLog`).
  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required DateTime createdAtUtc,
  }) : createdAtUtc = _requireUtc(createdAtUtc, 'createdAtUtc');

  /// Идентификатор записи в БД; 0 — сообщение ещё не сохранено
  /// (реальный id назначает autoIncrement).
  final int id;

  /// Сессия, к которой относится сообщение (ADR-046).
  final int sessionId;

  /// Кто отправил сообщение.
  final ChatRole role;

  /// Текст сообщения.
  final String content;

  /// Момент создания, в UTC.
  final DateTime createdAtUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          id == other.id &&
          sessionId == other.sessionId &&
          role == other.role &&
          content == other.content &&
          createdAtUtc == other.createdAtUtc;

  @override
  int get hashCode => Object.hash(id, sessionId, role, content, createdAtUtc);

  // Содержимое не попадает в toString: логи не должны содержать переписку.
  @override
  String toString() =>
      'ChatMessage($id, session: $sessionId, ${role.name}, '
      '${createdAtUtc.toIso8601String()})';
}
