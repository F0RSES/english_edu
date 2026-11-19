import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/domain/repositories/chat_repository.dart';
import 'package:english_edu/domain/repositories/chat_session_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/services/chat_generator.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';

/// Сколько последних сообщений уходит в контекст модели (ADR-041).
///
/// Лимит экономит токены: длинная история не нужна для типовых вопросов.
const _contextLimit = 10;

/// Отправляет сообщение помощнику и сохраняет оба сообщения (ADR-041).
///
/// Сообщение пользователя сохраняется до обращения к сети: при ошибке AI
/// оно остаётся в истории, а ответ просто не появляется. Диалоги разделены
/// на сессии (ADR-046): контекст модели ограничен активной сессией.
final class SendChatMessage {
  /// Создаёт use case; все зависимости внедряются.
  const SendChatMessage({
    required ChatRepository chat,
    required ChatSessionRepository sessions,
    required ChatGenerator ai,
    required SettingsRepository settings,
    required DateTime Function() clock,
  }) : _chat = chat,
       _sessions = sessions,
       _ai = ai,
       _settings = settings,
       _clock = clock;

  final ChatRepository _chat;
  final ChatSessionRepository _sessions;
  final ChatGenerator _ai;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Отправляет [userText] в сессию [sessionId], получает ответ и сохраняет
  /// оба сообщения.
  ///
  /// [sessionId] == null — новый диалог: сессия создаётся с автозаголовком
  /// из первых 30 символов сообщения (ADR-046). updatedAt сессии обновляется
  /// после каждого сохранённого сообщения. Контекст для AI — последние 10
  /// сообщений этой сессии, включая новое. Бросает [ArgumentError] на пустое
  /// сообщение; ошибки генератора пробрасываются без изменений. Возвращает
  /// ответ ассистента; его sessionId — id диалога (в т.ч. новой сессии).
  Future<ChatMessage> call(String userText, {int? sessionId}) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Empty message');
    }

    final settings = await _settings.get();
    final now = _clock().toUtc();

    final activeSessionId =
        sessionId ??
        (await _sessions.create(
          title: ChatSession.titleFromMessage(trimmed),
          createdAtUtc: now,
        )).id;

    await _chat.append(
      ChatMessage(
        id: 0,
        sessionId: activeSessionId,
        role: ChatRole.user,
        content: trimmed,
        createdAtUtc: now,
      ),
    );
    await _sessions.touch(activeSessionId, now);

    final history = await _chat.getLastN(
      _contextLimit,
      sessionId: activeSessionId,
    );
    final messages = history
        .map(
          (message) => (
            role: message.role == ChatRole.user ? 'user' : 'assistant',
            content: message.content,
          ),
        )
        .toList();

    final reply = await _ai.sendChat(
      messages: messages,
      level: settings.preferredLevel.label,
    );

    final replyAt = _clock().toUtc();
    final assistantMessage = ChatMessage(
      id: 0,
      sessionId: activeSessionId,
      role: ChatRole.assistant,
      content: reply,
      createdAtUtc: replyAt,
    );
    await _chat.append(assistantMessage);
    await _sessions.touch(activeSessionId, replyAt);

    return assistantMessage;
  }
}
