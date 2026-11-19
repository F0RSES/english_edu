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

/// Радиус скругления плитки сессии (Phase 43).
const _tileBorderRadius = 12.0;

/// Drawer истории чатов (Phase 42, ADR-046; Phase 43 — multi-select).
///
/// Список сессий с группировкой по времени: закреплённые сверху, затем
/// Сегодня / Вчера / Последние 7 дней / Старые (локальная TZ). Действия
/// над сессией — по кнопке «три точки»; long-press включает режим
/// множественного выбора с массовым удалением (DeepSeek-style).
class ChatHistoryDrawer extends ConsumerStatefulWidget {
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
  ConsumerState<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends ConsumerState<ChatHistoryDrawer> {
  /// Режим множественного выбора (Phase 43).
  bool _isSelectionMode = false;

  /// Id сессий, выбранных в режиме multi-select.
  final Set<int> _selectedSessions = {};

  void _startSelection(int sessionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedSessions.add(sessionId);
    });
  }

  /// Явный вход в режим выбора из хедера (Phase 44): пустой набор,
  /// корзина появится после первого выделения.
  void _enterSelectionMode() {
    setState(() => _isSelectionMode = true);
  }

  void _toggleSelection(int sessionId) {
    setState(() {
      if (!_selectedSessions.remove(sessionId)) {
        _selectedSessions.add(sessionId);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedSessions.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final lang = ref.read(languageProvider).value ?? AppLanguage.ru;
    final count = _selectedSessions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.chatDeleteBulkTitle(count, lang)),
        content: Text(S.chatDeleteBulkBody(lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.cancel(lang)),
          ),
          TextButton(
            key: const Key('chat-bulk-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.chatDelete(lang)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final ids = Set<int>.of(_selectedSessions);
    final repo = ref.read(chatSessionRepositoryProvider);
    for (final id in ids) {
      await repo.delete(id);
    }
    ref.invalidate(chatSessionsProvider);
    final activeDeleted = ids.contains(widget.activeSessionId);
    setState(() {
      _isSelectionMode = false;
      _selectedSessions.clear();
    });
    // Удаление активной сессии сбрасывает экран в новый чат (ADR-046).
    if (activeDeleted) {
      widget.onSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    final sessionsAsync = ref.watch(chatSessionsProvider);
    // SafeArea снаружи Drawer (Phase 44): вся панель, включая поверхность,
    // начинается ниже системного статус-бара. Внутренний SafeArea не нужен:
    // внешний снимает применённый padding с MediaQuery потомка.
    return SafeArea(
      child: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _isSelectionMode
                  ? Row(
                      children: [
                        IconButton(
                          key: const Key('chat-selection-cancel'),
                          tooltip: S.cancel(lang),
                          icon: const Icon(Icons.close),
                          onPressed: _cancelSelection,
                        ),
                        Expanded(
                          child: Text(
                            S.chatSelectedCount(_selectedSessions.length, lang),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (_selectedSessions.isNotEmpty)
                          IconButton(
                            key: const Key('chat-selection-delete'),
                            tooltip: S.chatDelete(lang),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => unawaited(_deleteSelected()),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.chatHistoryTitle(lang),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          key: const Key('chat-selection-enter'),
                          tooltip: S.chatSelectChats(lang),
                          icon: const Icon(Icons.checklist),
                          onPressed: _enterSelectionMode,
                        ),
                      ],
                    ),
            ),
            if (!_isSelectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FilledButton.icon(
                  key: const Key('chat-new-chat-button'),
                  onPressed: () => widget.onSelected(null),
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
                  activeSessionId: widget.activeSessionId,
                  isSelectionMode: _isSelectionMode,
                  selectedIds: _selectedSessions,
                  onSelected: widget.onSelected,
                  onToggleSelect: _toggleSelection,
                  onStartSelection: _startSelection,
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
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onSelected,
    required this.onToggleSelect,
    required this.onStartSelection,
    required this.lang,
  });

  final List<ChatSession> sessions;
  final int? activeSessionId;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final void Function(int? sessionId) onSelected;
  final void Function(int sessionId) onToggleSelect;
  final void Function(int sessionId) onStartSelection;
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
            isSelectionMode: isSelectionMode,
            isSelected: selectedIds.contains(session.id),
            onSelected: onSelected,
            onToggleSelect: onToggleSelect,
            onStartSelection: onStartSelection,
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

/// Одна сессия в списке. Обычный режим: тап — выбор, «три точки» — действия.
/// Режим выбора (Phase 43): тап и long-press переключают выделение.
class _SessionTile extends ConsumerWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelected,
    required this.onToggleSelect,
    required this.onStartSelection,
    required this.lang,
  });

  final ChatSession session;
  final bool isActive;
  final bool isSelectionMode;
  final bool isSelected;
  final void Function(int? sessionId) onSelected;
  final void Function(int sessionId) onToggleSelect;
  final void Function(int sessionId) onStartSelection;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        key: Key('chat-session-${session.id}'),
        // Скругление (Phase 43): shape задаёт InkWell.customBorder
        // (list_tile.dart SDK), поэтому selectedTileColor клиппится по
        // форме и не перекрывает углы; отдельный clipBehavior у ListTile нет.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_tileBorderRadius),
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelectionMode ? isSelected : isActive,
        selectedTileColor: scheme.secondaryContainer,
        leading: session.isPinned
            ? Icon(Icons.push_pin, size: 18, color: scheme.primary)
            : null,
        trailing: isSelectionMode
            ? Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              )
            : IconButton(
                key: Key('chat-session-menu-${session.id}'),
                icon: const Icon(Icons.more_vert),
                onPressed: () => unawaited(_openActions(context, ref)),
              ),
        onTap: () => isSelectionMode
            ? onToggleSelect(session.id)
            : onSelected(session.id),
        onLongPress: () => isSelectionMode
            ? onToggleSelect(session.id)
            : onStartSelection(session.id),
      ),
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
