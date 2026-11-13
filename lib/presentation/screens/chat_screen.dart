import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
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
  /// Создаёт экран чата.
  const ChatScreen({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить историю')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить ответ, проверьте интернет'),
          ),
        );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Все сообщения чата будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Очистить'),
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
    final showGreeting = _messages.isEmpty;
    final greetingOffset = showGreeting ? 1 : 0;
    final itemCount = _messages.length + greetingOffset + (_isSending ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощник'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == _clearAction) {
                unawaited(_clearHistory());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _clearAction,
                child: Text('Очистить историю'),
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
                  return const _GreetingBubble();
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
                      decoration: const InputDecoration(
                        hintText: 'Спроси про английский...',
                        border: OutlineInputBorder(),
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
  const _GreetingBubble();

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
          'Привет! Я помогу разобраться с английским. Спроси что-нибудь.',
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
