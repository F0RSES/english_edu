import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/chat_session_group.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Максимальная длина ручного названия сессии в диалоге переименования.
const _maxTitleLength = 60;

/// Drawer истории чатов (Phase 42, ADR-046).
///
/// Список сессий с группировкой по времени: закреплённые сверху, затем
/// Сегодня / Вчера / Последние 7 дней / Старые (локальная TZ). Действия
/// над сессией — по долгому нажатию или кнопке «три точки».
class ChatHistoryDrawer extends ConsumerWidget {
  /// Создаёт drawer; [onSelected] вызывается при выборе сессии
  /// (id — загрузить диалог, null — новый чат).
  const ChatHistoryDrawer({
    required this.activeSessionId,
    required this.onSelected,
    super.key,
  });

  /// Id активной сессии; null — новый пустой чат.
  final int? activeSessionId;

  /// Выбор сессии или сброс в новый чат.
  final void Function(int? sessionId) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final sessionsAsync = ref.watch(chatSessionsProvider);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                S.chatHistoryTitle(lang),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                key: const Key('chat-new-chat-button'),
                onPressed: () => onSelected(null),
                icon: const Icon(Icons.add),
                label: Text(S.chatNewChat(lang)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    Center(child: Text(S.chatHistoryLoadFailed(lang))),
                data: (sessions) => _SessionList(
                  sessions: sessions,
                  activeSessionId: activeSessionId,
                  onSelected: onSelected,
                  lang: lang,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Список сессий, сгруппированный по времени обновления.
class _SessionList extends ConsumerWidget {
  const _SessionList({
    required this.sessions,
    required this.activeSessionId,
    required this.onSelected,
    required this.lang,
  });

  final List<ChatSession> sessions;
  final int? activeSessionId;
  final void Function(int? sessionId) onSelected;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessions.isEmpty) {
      return Center(child: Text(S.chatHistoryEmpty(lang)));
    }
    final today = LocalDate.fromDateTime(ref.watch(clockProvider)().toLocal());
    final grouped = <ChatSessionGroup, List<ChatSession>>{};
    for (final session in sessions) {
      final group = ChatSessionGroup.of(
        isPinned: session.isPinned,
        updatedAtUtc: session.updatedAtUtc,
        today: today,
      );
      grouped.putIfAbsent(group, () => []).add(session);
    }
    // Порядок групп фиксирован; внутри группы сохраняется порядок getAll
    // (закреплённые первые, затем updatedAt по убыванию).
    final children = <Widget>[];
    for (final group in ChatSessionGroup.values) {
      final groupSessions = grouped[group];
      if (groupSessions == null) {
        continue;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            _groupLabel(group, lang),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
      for (final session in groupSessions) {
        children.add(
          _SessionTile(
            session: session,
            isActive: session.id == activeSessionId,
            onSelected: onSelected,
            lang: lang,
          ),
        );
      }
    }
    return ListView(children: children);
  }

  String _groupLabel(ChatSessionGroup group, AppLanguage lang) =>
      switch (group) {
        ChatSessionGroup.pinned => S.chatGroupPinned(lang),
        ChatSessionGroup.today => S.chatGroupToday(lang),
        ChatSessionGroup.yesterday => S.chatGroupYesterday(lang),
        ChatSessionGroup.lastSevenDays => S.chatGroupLastSevenDays(lang),
        ChatSessionGroup.older => S.chatGroupOlder(lang),
      };
}

/// Одна сессия в списке: тап — выбор, long-press и «три точки» — действия.
class _SessionTile extends ConsumerWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onSelected,
    required this.lang,
  });

  final ChatSession session;
  final bool isActive;
  final void Function(int? sessionId) onSelected;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('chat-session-${session.id}'),
      title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: isActive,
      selectedTileColor: scheme.secondaryContainer,
      leading: session.isPinned
          ? Icon(Icons.push_pin, size: 18, color: scheme.primary)
          : null,
      trailing: IconButton(
        key: Key('chat-session-menu-${session.id}'),
        icon: const Icon(Icons.more_vert),
        onPressed: () => unawaited(_openActions(context, ref)),
      ),
      onTap: () => onSelected(session.id),
      onLongPress: () => unawaited(_openActions(context, ref)),
    );
  }

  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('chat-session-rename'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(S.chatRename(lang)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_rename(context, ref));
              },
            ),
            ListTile(
              key: const Key('chat-session-pin'),
              leading: Icon(
                session.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(
                session.isPinned ? S.chatUnpin(lang) : S.chatPin(lang),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_togglePin(ref));
              },
            ),
            ListTile(
              key: const Key('chat-session-delete'),
              leading: const Icon(Icons.delete_outline),
              title: Text(S.chatDelete(lang)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_delete(context, ref));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final renamed = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initialTitle: session.title, lang: lang),
    );
    if (renamed == null || renamed.trim().isEmpty || !context.mounted) {
      return;
    }
    await ref.read(chatSessionRepositoryProvider).rename(session.id, renamed);
    ref.invalidate(chatSessionsProvider);
  }

  Future<void> _togglePin(WidgetRef ref) async {
    await ref.read(chatSessionRepositoryProvider).togglePin(session.id);
    ref.invalidate(chatSessionsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.chatDeleteTitle(lang)),
        content: Text(S.chatDeleteBody(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.cancel(lang)),
          ),
          TextButton(
            key: const Key('chat-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.chatDelete(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(chatSessionRepositoryProvider).delete(session.id);
    ref.invalidate(chatSessionsProvider);
    // Удаление активной сессии сбрасывает экран в новый чат (ADR-046).
    if (isActive) {
      onSelected(null);
    }
  }
}

/// Диалог переименования: владеет контроллером поля, чтобы он не диспозился
/// раньше, чем закроется route диалога (иначе TextField строится с уже
/// disposed контроллером).
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialTitle, required this.lang});

  final String initialTitle;
  final AppLanguage lang;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.chatRenameTitle(widget.lang)),
      content: TextField(
        key: const Key('chat-rename-field'),
        controller: _controller,
        autofocus: true,
        maxLength: _maxTitleLength,
        decoration: InputDecoration(hintText: S.chatRenameHint(widget.lang)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.cancel(widget.lang)),
        ),
        TextButton(
          key: const Key('chat-rename-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(S.save(widget.lang)),
        ),
      ],
    );
  }
}
