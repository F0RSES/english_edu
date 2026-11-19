import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/presentation/widgets/chat_history_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_chat_session_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';

final _now = DateTime.utc(2026, 11, 19, 12);

ChatSession session({required int id, required String title}) => ChatSession(
  id: id,
  title: title,
  isPinned: false,
  createdAtUtc: _now,
  updatedAtUtc: _now,
);

Widget host({
  required FakeChatSessionRepository sessions,
  int? activeSessionId,
  void Function(int? sessionId)? onSelected,
  EdgeInsets padding = EdgeInsets.zero,
}) => ProviderScope(
  overrides: [
    chatSessionRepositoryProvider.overrideWithValue(sessions),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    clockProvider.overrideWithValue(() => _now),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: padding),
      child: child!,
    ),
    home: ChatHistoryDrawer(
      activeSessionId: activeSessionId,
      onSelected: onSelected ?? (_) {},
    ),
  ),
);

void main() {
  testWidgets('should_round_tile_corners_when_rendered', (tester) async {
    await tester.pumpWidget(
      host(sessions: FakeChatSessionRepository([session(id: 1, title: 'Чат')])),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('chat-session-1')),
    );
    // shape задаёт InkWell.customBorder: цвет выделения клиппится по форме.
    expect(
      tile.shape,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  });

  testWidgets('should_enter_selection_mode_on_long_press', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();

    expect(find.text('Выбрано: 1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    // Меню и «Новый чат» скрыты в режиме выбора.
    expect(find.byKey(const Key('chat-session-menu-1')), findsNothing);
    expect(find.byKey(const Key('chat-new-chat-button')), findsNothing);
    expect(find.byKey(const Key('chat-selection-cancel')), findsOneWidget);
    expect(find.byKey(const Key('chat-selection-delete')), findsOneWidget);
  });

  testWidgets('should_toggle_selection_on_tap_in_selection_mode', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-session-2')));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 2'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('chat-session-2')));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('should_exit_selection_mode_on_cancel', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-selection-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('История чатов'), findsOneWidget);
    expect(find.byKey(const Key('chat-new-chat-button')), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byKey(const Key('chat-session-menu-1')), findsOneWidget);
  });

  testWidgets('should_hide_bulk_delete_when_nothing_selected', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-selection-delete')), findsOneWidget);

    // Снимаем выделение с единственного выбранного чата.
    await tester.tap(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 0'), findsOneWidget);
    expect(find.byKey(const Key('chat-selection-delete')), findsNothing);
  });

  testWidgets('should_delete_selected_sessions_on_bulk_confirm', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
      session(id: 2, title: 'Второй'),
      session(id: 3, title: 'Третий'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-2')));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-selection-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Удалить 2 чата?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-bulk-delete-confirm')));
    await tester.pumpAndSettle();

    expect(sessions.sessions.map((s) => s.id), [3]);
    // Режим выбора выключен, список обновлён.
    expect(find.text('История чатов'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text('Первый'), findsNothing);
    expect(find.text('Третий'), findsOneWidget);
  });

  testWidgets('should_use_singular_form_when_one_chat_selected', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-selection-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Удалить 1 чат?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(sessions.sessions, hasLength(1));
  });

  testWidgets('should_reset_to_new_chat_when_active_session_deleted', (
    tester,
  ) async {
    final calls = <int?>[];
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Активный'),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(
      host(sessions: sessions, activeSessionId: 1, onSelected: calls.add),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-selection-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-bulk-delete-confirm')));
    await tester.pumpAndSettle();

    expect(calls, [null]);
    expect(sessions.sessions.map((s) => s.id), [2]);
  });

  testWidgets('should_keep_current_chat_when_active_not_deleted', (
    tester,
  ) async {
    final calls = <int?>[];
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
      session(id: 2, title: 'Второй'),
      session(id: 3, title: 'Активный'),
    ]);
    await tester.pumpWidget(
      host(sessions: sessions, activeSessionId: 3, onSelected: calls.add),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-selection-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-bulk-delete-confirm')));
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(sessions.sessions.map((s) => s.id), [3]);
    expect(find.text('История чатов'), findsOneWidget);
  });

  testWidgets('should_open_chat_on_tap_in_normal_mode', (tester) async {
    final calls = <int?>[];
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(host(sessions: sessions, onSelected: calls.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-session-2')));
    await tester.pumpAndSettle();

    expect(calls, [2]);
  });

  testWidgets('should_open_actions_sheet_from_menu_in_normal_mode', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-session-menu-1')));
    await tester.pumpAndSettle();

    expect(find.text('Переименовать'), findsOneWidget);
    expect(find.text('Закрепить'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
  });

  testWidgets('should_enter_selection_mode_from_header_icon', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-selection-enter')));
    await tester.pumpAndSettle();

    // Пустой набор: счётчик 0, корзина скрыта до первого выделения.
    expect(find.text('Выбрано: 0'), findsOneWidget);
    expect(find.byKey(const Key('chat-selection-cancel')), findsOneWidget);
    expect(find.byKey(const Key('chat-selection-delete')), findsNothing);
    expect(find.byKey(const Key('chat-new-chat-button')), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 1'), findsOneWidget);
    expect(find.byKey(const Key('chat-selection-delete')), findsOneWidget);
  });

  testWidgets('should_restore_header_after_cancel_from_icon_entry', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-selection-enter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-selection-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('История чатов'), findsOneWidget);
    expect(find.byKey(const Key('chat-selection-enter')), findsOneWidget);
    expect(find.byKey(const Key('chat-new-chat-button')), findsOneWidget);
  });

  testWidgets('should_inset_drawer_below_status_bar', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(
      host(sessions: sessions, padding: const EdgeInsets.only(top: 40)),
    );
    await tester.pumpAndSettle();

    // SafeArea снаружи Drawer: панель целиком ниже статус-бара.
    expect(
      find.byWidgetPredicate((w) => w is SafeArea && w.child is Drawer),
      findsOneWidget,
    );
    expect(tester.getTopLeft(find.byType(Drawer)).dy, greaterThanOrEqualTo(40));
  });

  testWidgets('should_pad_tile_content_in_both_modes', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Первый'),
    ]);
    await tester.pumpWidget(host(sessions: sessions));
    await tester.pumpAndSettle();

    // Phase 46: явные отступы контента плитки — меню внутри скругления.
    const expected = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
    var tile = tester.widget<ListTile>(find.byKey(const Key('chat-session-1')));
    expect(tile.contentPadding, expected);

    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();
    tile = tester.widget<ListTile>(find.byKey(const Key('chat-session-1')));
    expect(tile.contentPadding, expected);
  });
}
