import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Значение пункта меню «Очистить историю».
const _clearAction = 'clear';

/// Доля ширины экрана, которую занимает пузырь сообщения.
const _maxBubbleWidthFactor = 0.8;

/// Чат с AI-помощником (Phase 25a, ADR-041).
///
/// История хранится локально; сеть используется только по явной отправке
/// сообщения. Приветствие — заглушка UI, в БД не сохраняется.
class ChatScreen extends ConsumerStatefulWidget {
  /// Создаёт экран чата; [initialContext] предзаполняет поле ввода.
  const ChatScreen({this.initialContext, super.key});

  /// Начальный запрос от карточки слова (Phase 39d): пользователь сразу
  /// отправляет его или редактирует. null — пустое поле ввода.
  final String? initialContext;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialContext;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
    }
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final messages = await ref.read(chatHistoryProvider.future);
      if (!mounted) {
        return;
      }
      setState(() => _messages = messages);
      _scrollToBottom();
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
      final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.chatHistoryLoadFailed(lang))));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_isSending || text.isEmpty) {
      return;
    }
    setState(() => _isSending = true);
    try {
      await ref.read(sendChatMessageProvider)(text);
      _controller.clear();
    } on Object catch (_) {
      if (mounted) {
        final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.chatReplyFailed(lang))));
      }
    } finally {
      if (mounted) {
        // Перезагружаем и при ошибке: сообщение пользователя уже сохранено.
        ref.invalidate(chatHistoryProvider);
        await _loadHistory();
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _clearHistory() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.chatClearTitle(lang)),
        content: Text(S.chatClearBody(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.cancel(lang)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.chatClear(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(chatRepositoryProvider).clear();
    ref.invalidate(chatHistoryProvider);
    await _loadHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final showGreeting = _messages.isEmpty;
    final greetingOffset = showGreeting ? 1 : 0;
    final itemCount = _messages.length + greetingOffset + (_isSending ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.assistant(lang)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == _clearAction) {
                unawaited(_clearHistory());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _clearAction,
                child: Text(S.chatClearHistory(lang)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (showGreeting && index == 0) {
                  return _GreetingBubble(lang: lang);
                }
                final messageIndex = index - greetingOffset;
                if (messageIndex >= _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[messageIndex]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: S.chatHint(lang),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('chat-send-button'),
                    icon: const Icon(Icons.send),
                    color: scheme.primary,
                    onPressed: _isSending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пузырь одного сообщения: user справа, assistant слева.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxBubbleWidthFactor,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}

/// Приветствие-заглушка: только UI, в БД не сохраняется.
class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxBubbleWidthFactor,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          S.chatGreeting(lang),
          style: TextStyle(color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// Индикатор «помощник печатает»: три точки, без бесконечной анимации
/// (иначе pumpAndSettle в тестах не завершится).
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      key: const Key('chat-typing-indicator'),
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
