import 'dart:async';
import 'dart:convert';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:english_edu/presentation/screens/chat_screen.dart';
import 'package:english_edu/presentation/widgets/ai_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_chat_repository.dart';
import '../../domain/usecases/fakes/fake_chat_session_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';

final _now = DateTime.utc(2026, 11, 13, 12);

const _greeting =
    'Привет! Я Маффин — помогу разобраться с английским. Спроси что-нибудь.';

http.Response okResponse() => http.Response(
  jsonEncode({'message': 'Ответ бота'}),
  200,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

ChatSession session({
  required int id,
  required String title,
  bool isPinned = false,
  DateTime? updatedAtUtc,
}) => ChatSession(
  id: id,
  title: title,
  isPinned: isPinned,
  createdAtUtc: updatedAtUtc ?? _now,
  updatedAtUtc: updatedAtUtc ?? _now,
);

ChatMessage message({
  required int id,
  required int sessionId,
  required String content,
  ChatRole role = ChatRole.user,
}) => ChatMessage(
  id: id,
  sessionId: sessionId,
  role: role,
  content: content,
  createdAtUtc: _now,
);

Widget host({
  required FakeChatRepository chat,
  required http.Client httpClient,
  FakeChatSessionRepository? sessions,
  UserSettings? settings,
  String? initialContext,
}) => ProviderScope(
  overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
    chatSessionRepositoryProvider.overrideWithValue(
      sessions ?? FakeChatSessionRepository(),
    ),
    aiClientProvider.overrideWithValue(AiClient(httpClient)),
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings),
    ),
    clockProvider.overrideWithValue(() => _now),
  ],
  child: MaterialApp(home: ChatScreen(initialContext: initialContext)),
);

/// Рекурсивный поиск жирного span с [text] в дереве RichText
/// (Markdown-рендер ответа ассистента, Phase 45).
bool _spanHasBold(InlineSpan span, String text) {
  if (span is! TextSpan) {
    return false;
  }
  if (span.style?.fontWeight == FontWeight.bold &&
      (span.text?.contains(text) ?? false)) {
    return true;
  }
  final children = span.children;
  return children != null && children.any((child) => _spanHasBold(child, text));
}

bool _hasBoldSpan(WidgetTester tester, String text) => tester
    .widgetList<RichText>(find.byType(RichText))
    .any((rich) => _spanHasBold(rich.text, text));

void main() {
  // Аватар повторяет анимацию вечно: без запрета анимаций pumpAndSettle
  // не завершится. Запрет уважается и роутами (меню/диалоги открываются
  // мгновенно), в отличие от TickerMode, который морозит и их.
  setUp(() {
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('renders empty state with greeting', (tester) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_greeting), findsOneWidget);
  });

  testWidgets('initialContext prefills the input without sending', (
    tester,
  ) async {
    const prompt =
        "Расскажи подробнее про слово 'could' (перевод: мог, "
        'часть речи: verb). Какие у него формы, примеры использования '
        'и типичные ошибки?';
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
        initialContext: prompt,
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, prompt);
    // Контекст не отправляется автоматически: приветствие ещё на месте
    // (после отправки оно исчезает — см. тест отправки выше).
    expect(find.text(_greeting), findsOneWidget);
  });

  testWidgets('app bar shows Muffin title without avatar', (tester) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    // Phase 44: в AppBar только текст; аватар — лишь в приветствии.
    expect(find.text('Маффин'), findsOneWidget);
    expect(find.byType(AiAvatar), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == 'main_chat_hero'),
      findsNothing,
    );
  });

  testWidgets('messages show messenger-style avatars', (tester) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    // До отправки: только аватар приветствия (AppBar без аватара, Phase 44).
    expect(find.byType(AiAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);

    await tester.enterText(find.byType(TextField), 'Привет');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    // После отправки: пузырь ассистента; у пузыря юзера — person.
    expect(find.byType(AiAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Привет'), findsOneWidget);
    expect(find.text('Ответ бота'), findsOneWidget);
  });

  testWidgets('typing message and sending adds to list', (tester) async {
    final chat = FakeChatRepository();
    await tester.pumpWidget(
      host(chat: chat, httpClient: MockClient((_) async => okResponse())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Привет');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Привет'), findsOneWidget);
    expect(find.text('Ответ бота'), findsOneWidget);
    expect(chat.messages.length, 2);
    expect(find.text(_greeting), findsNothing);
  });

  testWidgets('shows typing indicator while sending', (tester) async {
    final gate = Completer<void>();
    final chat = FakeChatRepository();
    await tester.pumpWidget(
      host(
        chat: chat,
        httpClient: MockClient((_) async {
          await gate.future;
          return okResponse();
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Привет');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pump();

    expect(find.byKey(const Key('chat-typing-indicator')), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-typing-indicator')), findsNothing);
    expect(find.text('Ответ бота'), findsOneWidget);
  });

  testWidgets('shows error snackbar on failure', (tester) async {
    final chat = FakeChatRepository();
    await tester.pumpWidget(
      host(
        chat: chat,
        httpClient: MockClient((_) async => http.Response('boom', 500)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Привет');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось получить ответ, проверьте интернет'),
      findsOneWidget,
    );
    // Сообщение пользователя переживает ошибку AI.
    expect(chat.messages.length, 1);
  });

  testWidgets('clear history asks for confirmation and empties the list', (
    tester,
  ) async {
    final chat = FakeChatRepository([
      message(id: 1, sessionId: 1, content: 'Старое сообщение'),
    ]);
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Старый чат'),
    ]);
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Старое сообщение'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Очистить историю'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();

    expect(chat.messages, isEmpty);
    expect(find.text('Старое сообщение'), findsNothing);
    expect(find.text(_greeting), findsOneWidget);
  });

  testWidgets('switches to EN labels when lang=en', (tester) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
        settings: const UserSettings(language: AppLanguage.en),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Muffin'), findsOneWidget);
    expect(
      find.text(
        "Hi! I'm Muffin — I can help you with English. Ask me anything.",
      ),
      findsOneWidget,
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Ask about English...');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();

    expect(find.text('Clear history?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('drawer shows sessions grouped by time with pinned on top', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([
      session(
        id: 1,
        title: 'Закреплённый старый',
        isPinned: true,
        updatedAtUtc: _now.subtract(const Duration(days: 30)),
      ),
      session(id: 2, title: 'Сегодняшний'),
      session(
        id: 3,
        title: 'Вчерашний',
        updatedAtUtc: _now.subtract(const Duration(days: 1)),
      ),
      session(
        id: 4,
        title: 'Недельный',
        updatedAtUtc: _now.subtract(const Duration(days: 5)),
      ),
      session(
        id: 5,
        title: 'Древний',
        updatedAtUtc: _now.subtract(const Duration(days: 10)),
      ),
    ]);
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('История чатов'), findsOneWidget);
    expect(find.text('Закрепленные'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Вчера'), findsOneWidget);
    expect(find.text('Последние 7 дней'), findsOneWidget);
    expect(find.text('Старые'), findsOneWidget);
    expect(find.text('Закреплённый старый'), findsOneWidget);
    expect(find.text('Сегодняшний'), findsOneWidget);
    expect(find.text('Вчерашний'), findsOneWidget);
    expect(find.text('Недельный'), findsOneWidget);
    expect(find.text('Древний'), findsOneWidget);
  });

  testWidgets('restores most recent session on open', (tester) async {
    final chat = FakeChatRepository([
      message(id: 1, sessionId: 1, content: 'Сообщение первого'),
      message(id: 2, sessionId: 2, content: 'Сообщение второго'),
    ]);
    final sessions = FakeChatSessionRepository([
      session(
        id: 1,
        title: 'Первый',
        updatedAtUtc: _now.subtract(const Duration(hours: 1)),
      ),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сообщение второго'), findsOneWidget);
    expect(find.text('Сообщение первого'), findsNothing);
    expect(find.text(_greeting), findsNothing);
  });

  testWidgets('selecting a session in drawer loads its messages', (
    tester,
  ) async {
    final chat = FakeChatRepository([
      message(id: 1, sessionId: 1, content: 'Сообщение первого'),
      message(id: 2, sessionId: 2, content: 'Сообщение второго'),
    ]);
    final sessions = FakeChatSessionRepository([
      session(
        id: 1,
        title: 'Первый',
        updatedAtUtc: _now.subtract(const Duration(hours: 1)),
      ),
      session(id: 2, title: 'Второй'),
    ]);
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Первый'));
    await tester.pumpAndSettle();

    expect(find.text('Сообщение первого'), findsOneWidget);
    expect(find.text('Сообщение второго'), findsNothing);
    // Drawer закрылся после выбора.
    expect(find.text('История чатов'), findsNothing);
  });

  testWidgets('initialContext starts a new chat despite existing sessions', (
    tester,
  ) async {
    final chat = FakeChatRepository([
      message(id: 1, sessionId: 1, content: 'Старое сообщение'),
    ]);
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Старый чат'),
    ]);
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
        initialContext: 'Вопрос про слово could',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_greeting), findsOneWidget);
    expect(find.text('Старое сообщение'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Вопрос про слово could');
  });

  testWidgets('highlights the active session in drawer', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Активный'),
      session(
        id: 2,
        title: 'Неактивный',
        updatedAtUtc: _now.subtract(const Duration(hours: 1)),
      ),
    ]);
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    final active = tester.widget<ListTile>(
      find.byKey(const Key('chat-session-1')),
    );
    final inactive = tester.widget<ListTile>(
      find.byKey(const Key('chat-session-2')),
    );
    expect(active.selected, isTrue);
    expect(inactive.selected, isFalse);
  });

  testWidgets('renames a session from the bottom sheet', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Старое имя'),
    ]);
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-rename')));
    await tester.pumpAndSettle();

    expect(find.text('Переименовать чат'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('chat-rename-field')),
      'Новое имя',
    );
    await tester.tap(find.byKey(const Key('chat-rename-save')));
    await tester.pumpAndSettle();

    expect(sessions.sessions.single.title, 'Новое имя');
    // Переименование не дергает updatedAt: список не прыгает.
    expect(sessions.sessions.single.updatedAtUtc, _now);
    expect(find.text('Новое имя'), findsOneWidget);
    expect(find.text('Старое имя'), findsNothing);
  });

  testWidgets('pins a session from the bottom sheet', (tester) async {
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Обычный чат'),
    ]);
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Закрепленные'), findsNothing);

    await tester.tap(find.byKey(const Key('chat-session-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-pin')));
    await tester.pumpAndSettle();

    expect(sessions.sessions.single.isPinned, isTrue);
    expect(sessions.sessions.single.updatedAtUtc, _now);
    expect(find.text('Закрепленные'), findsOneWidget);
  });

  testWidgets('long press enters selection mode instead of the sheet', (
    tester,
  ) async {
    final sessions = FakeChatSessionRepository([session(id: 1, title: 'Чат')]);
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('chat-session-1')));
    await tester.pumpAndSettle();

    expect(find.text('Выбрано: 1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Переименовать'), findsNothing);
  });

  testWidgets('deletes active session with confirmation and resets to new', (
    tester,
  ) async {
    final chat = FakeChatRepository([
      message(id: 1, sessionId: 1, content: 'Сообщение активного'),
    ]);
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Активный чат'),
    ]);
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Сообщение активного'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-session-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Удалить чат?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-delete-confirm')));
    await tester.pumpAndSettle();

    expect(sessions.sessions, isEmpty);
    // Экран сброшен в новый чат: приветствие вместо сообщений.
    expect(find.text(_greeting), findsOneWidget);
    expect(find.text('Сообщение активного'), findsNothing);
  });

  testWidgets('new chat button resets to empty state', (tester) async {
    final chat = FakeChatRepository([
      message(id: 1, sessionId: 1, content: 'Сообщение активного'),
    ]);
    final sessions = FakeChatSessionRepository([
      session(id: 1, title: 'Активный чат'),
    ]);
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-new-chat-button')));
    await tester.pumpAndSettle();

    expect(find.text(_greeting), findsOneWidget);
    expect(find.text('Сообщение активного'), findsNothing);
    // Пустая сессия в БД не создаётся: список не засоряется.
    expect(sessions.sessions, hasLength(1));
  });

  testWidgets('shows nickname initials in the user bubble', (tester) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
        settings: const UserSettings(nickname: 'Norman Smith'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Привет');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('NS'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('failed send in new chat keeps session for the next send', (
    tester,
  ) async {
    final chat = FakeChatRepository();
    final sessions = FakeChatSessionRepository();
    var calls = 0;
    await tester.pumpWidget(
      host(
        chat: chat,
        sessions: sessions,
        httpClient: MockClient((_) async {
          calls++;
          return calls == 1 ? http.Response('boom', 500) : okResponse();
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Первый вопрос');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();
    expect(sessions.sessions, hasLength(1));

    // SnackBar ошибки перекрывает поле ввода: ждём его автозакрытия.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Второй вопрос');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    // Дубль сессии не создан: все сообщения в одном диалоге.
    expect(sessions.sessions, hasLength(1));
    expect(chat.messages, hasLength(3));
    expect(
      chat.messages.every((m) => m.sessionId == sessions.sessions.single.id),
      isTrue,
    );
  });

  testWidgets('assistant markdown renders bold without raw asterisks', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'message': '**hello**'}),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Привет');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    // Сырых звёзд нет, жирный span отрендерен (Phase 45).
    expect(find.text('**hello**'), findsNothing);
    expect(_hasBoldSpan(tester, 'hello'), isTrue);
  });

  testWidgets('user message keeps raw markdown text', (tester) async {
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient((_) async => okResponse()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '**hello**');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    // Пользовательский пузырь — обычный Text: звёзды видны как есть.
    expect(find.text('**hello**'), findsOneWidget);
  });

  testWidgets('long markdown answer with code block does not overflow', (
    tester,
  ) async {
    final longLine = 'x' * 300;
    final answer =
        'Вот примеры:\n\n'
        '- First example sentence\n'
        '- Second example sentence\n\n'
        '```\n$longLine\n```\n\n'
        'И очень длинное слово: ${'y' * 200}.';
    await tester.pumpWidget(
      host(
        chat: FakeChatRepository(),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'message': answer}),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Примеры');
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    // Переполнения ловятся тестовым фреймворком; здесь — явная проверка.
    expect(tester.takeException(), isNull);
    expect(find.textContaining('First example sentence'), findsOneWidget);
    expect(find.textContaining('Second example sentence'), findsOneWidget);
  });
}
