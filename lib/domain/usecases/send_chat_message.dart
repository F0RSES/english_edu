import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/repositories/chat_repository.dart';
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
/// оно остаётся в истории, а ответ просто не появляется.
final class SendChatMessage {
  /// Создаёт use case; все зависимости внедряются.
  const SendChatMessage({
    required ChatRepository chat,
    required ChatGenerator ai,
    required SettingsRepository settings,
    required DateTime Function() clock,
  }) : _chat = chat,
       _ai = ai,
       _settings = settings,
       _clock = clock;

  final ChatRepository _chat;
  final ChatGenerator _ai;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Отправляет [userText], получает ответ и сохраняет оба сообщения.
  ///
  /// Контекст для AI — последние 10 сообщений, включая новое. Бросает
  /// [ArgumentError] на пустое сообщение; ошибки генератора пробрасываются
  /// без изменений.
  Future<ChatMessage> call(String userText) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Empty message');
    }

    final settings = await _settings.get();
    final now = _clock().toUtc();

    await _chat.append(
      ChatMessage(
        id: 0,
        role: ChatRole.user,
        content: trimmed,
        createdAtUtc: now,
      ),
    );

    final history = await _chat.getLastN(_contextLimit);
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

    final assistantMessage = ChatMessage(
      id: 0,
      role: ChatRole.assistant,
      content: reply,
      createdAtUtc: _clock().toUtc(),
    );
    await _chat.append(assistantMessage);

    return assistantMessage;
  }
}
