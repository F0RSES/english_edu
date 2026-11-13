import 'dart:async';
import 'dart:convert';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:english_edu/presentation/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_chat_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';

final _now = DateTime.utc(2026, 11, 13, 12);

const _greeting =
    'Привет! Я помогу разобраться с английским. Спроси что-нибудь.';

http.Response okResponse() => http.Response(
  jsonEncode({'message': 'Ответ бота'}),
  200,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

Widget host({
  required FakeChatRepository chat,
  required http.Client httpClient,
}) => ProviderScope(
  overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
    aiClientProvider.overrideWithValue(AiClient(httpClient)),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    clockProvider.overrideWithValue(() => _now),
  ],
  child: const MaterialApp(home: ChatScreen()),
);

void main() {
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
      ChatMessage(
        id: 1,
        role: ChatRole.user,
        content: 'Старое сообщение',
        createdAtUtc: _now,
      ),
    ]);
    await tester.pumpWidget(
      host(chat: chat, httpClient: MockClient((_) async => okResponse())),
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
}
