import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Сессия чата с AI-помощником (Phase 42, ADR-046).
///
/// Группирует сообщения в отдельные диалоги: список сессий показывается
/// в drawer истории, удаление сессии каскадно удаляет её сообщения.
@immutable
final class ChatSession {
  /// Создаёт сессию; [createdAtUtc] и [updatedAtUtc] должны быть в UTC.
  ///
  /// Не `const`: время проверяется в runtime, потому что assert вырезается
  /// в release-сборке (паттерн `ChatMessage`).
  ChatSession({
    required this.id,
    required this.title,
    required this.isPinned,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
  }) : createdAtUtc = _requireUtc(createdAtUtc, 'createdAtUtc'),
       updatedAtUtc = _requireUtc(updatedAtUtc, 'updatedAtUtc');

  /// Идентификатор записи в БД; 0 — сессия ещё не сохранена
  /// (реальный id назначает autoIncrement).
  final int id;

  /// Заголовок сессии в списке истории.
  final String title;

  /// Закреплена ли сессия вверху списка.
  final bool isPinned;

  /// Момент создания, в UTC.
  final DateTime createdAtUtc;

  /// Момент последнего сообщения, в UTC. Переименование и закрепление
  /// его не меняют, чтобы список не пересортировывался.
  final DateTime updatedAtUtc;

  /// Лимит символов автозаголовка из первого сообщения (ADR-046).
  static const autoTitleLimit = 30;

  /// Автозаголовок: первые [autoTitleLimit] символов [firstMessage].
  static String titleFromMessage(String firstMessage) =>
      firstMessage.length <= autoTitleLimit
      ? firstMessage
      : firstMessage.substring(0, autoTitleLimit);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSession &&
          id == other.id &&
          title == other.title &&
          isPinned == other.isPinned &&
          createdAtUtc == other.createdAtUtc &&
          updatedAtUtc == other.updatedAtUtc;

  @override
  int get hashCode =>
      Object.hash(id, title, isPinned, createdAtUtc, updatedAtUtc);

  // Заголовок не попадает в toString: он содержит текст пользователя.
  @override
  String toString() =>
      'ChatSession($id, pinned: $isPinned, '
      '${createdAtUtc.toIso8601String()})';
}
