import 'dart:convert';

import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:english_edu/domain/usecases/send_chat_message.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fakes/fake_chat_repository.dart';
import 'fakes/fake_chat_session_repository.dart';
import 'fakes/fake_settings_repository.dart';

final _now = DateTime.utc(2026, 11, 13, 12);

http.Response jsonResponse(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('sends message, receives reply, saves both', () async {
    Object? capturedBody;
    final chat = FakeChatRepository();
    final sessions = FakeChatSessionRepository();
    final useCase = SendChatMessage(
      chat: chat,
      sessions: sessions,
      ai: AiClient(
        MockClient((request) async {
          capturedBody = jsonDecode(request.body);
          return jsonResponse({'message': 'Привет! Чем помочь?'}, 200);
        }),
      ),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    final reply = await useCase('  Привет  ');

    expect(reply.role, ChatRole.assistant);
    expect(reply.content, 'Привет! Чем помочь?');
    expect(chat.messages.length, 2);
    expect(chat.messages[0].role, ChatRole.user);
    expect(chat.messages[0].content, 'Привет');
    expect(chat.messages[1].role, ChatRole.assistant);
    expect(capturedBody, {
      'type': 'chat',
      'messages': [
        {'role': 'system', 'content': contains('Markdown')},
        {'role': 'user', 'content': 'Привет'},
      ],
      'word': 'A1',
    });
  });

  test(
    'should_create_session_with_auto_title_when_session_id_is_null',
    () async {
      final chat = FakeChatRepository();
      final sessions = FakeChatSessionRepository();
      final useCase = SendChatMessage(
        chat: chat,
        sessions: sessions,
        ai: AiClient(
          MockClient((_) async => jsonResponse({'message': 'ok'}, 200)),
        ),
        settings: FakeSettingsRepository(),
        clock: () => _now,
      );
      const longText = 'Как сказать «доброе утро» по-английски вежливо?';

      final reply = await useCase(longText);

      expect(sessions.sessions, hasLength(1));
      final created = sessions.sessions.single;
      expect(created.title, longText.substring(0, ChatSession.autoTitleLimit));
      expect(created.createdAtUtc, _now);
      expect(reply.sessionId, created.id);
      expect(chat.messages.every((m) => m.sessionId == created.id), isTrue);
    },
  );

  test('should_reuse_session_when_session_id_given', () async {
    final existing = ChatSession(
      id: 7,
      title: 'Старый диалог',
      isPinned: false,
      createdAtUtc: _now.subtract(const Duration(days: 1)),
      updatedAtUtc: _now.subtract(const Duration(days: 1)),
    );
    final chat = FakeChatRepository();
    final sessions = FakeChatSessionRepository([existing]);
    final useCase = SendChatMessage(
      chat: chat,
      sessions: sessions,
      ai: AiClient(
        MockClient((_) async => jsonResponse({'message': 'ok'}, 200)),
      ),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    final reply = await useCase('Продолжаем', sessionId: 7);

    expect(sessions.sessions, hasLength(1));
    expect(reply.sessionId, 7);
    expect(chat.messages.every((m) => m.sessionId == 7), isTrue);
  });

  test('should_touch_session_after_each_message_when_sending', () async {
    final chat = FakeChatRepository();
    final sessions = FakeChatSessionRepository();
    final useCase = SendChatMessage(
      chat: chat,
      sessions: sessions,
      ai: AiClient(
        MockClient((_) async => jsonResponse({'message': 'ok'}, 200)),
      ),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    await useCase('Привет');

    expect(sessions.sessions.single.updatedAtUtc, _now);
  });

  test('limits context to last 10 messages of the session', () async {
    Object? capturedBody;
    final initial = [
      for (var i = 1; i <= 12; i++)
        ChatMessage(
          id: i,
          sessionId: 1,
          role: i.isEven ? ChatRole.assistant : ChatRole.user,
          content: 'msg $i',
          createdAtUtc: _now.add(Duration(minutes: i)),
        ),
      // Сообщение чужой сессии не должно попасть в контекст.
      ChatMessage(
        id: 13,
        sessionId: 2,
        role: ChatRole.user,
        content: 'чужая сессия',
        createdAtUtc: _now.add(const Duration(minutes: 13)),
      ),
    ];
    final chat = FakeChatRepository(initial);
    final sessions = FakeChatSessionRepository([
      ChatSession(
        id: 1,
        title: 'Диалог',
        isPinned: false,
        createdAtUtc: _now,
        updatedAtUtc: _now,
      ),
    ]);
    final useCase = SendChatMessage(
      chat: chat,
      sessions: sessions,
      ai: AiClient(
        MockClient((request) async {
          capturedBody = jsonDecode(request.body);
          return jsonResponse({'message': 'ok'}, 200);
        }),
      ),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    await useCase('new question', sessionId: 1);

    // 12 старых + 1 новое = 13; в контекст уходят последние 10:
    // msg 4…12 плюс новое; чужая сессия исключена. Системный промт
    // добавляется транспортом (Phase 46) и в лимит не входит.
    expect(capturedBody, {
      'type': 'chat',
      'messages': [
        {'role': 'system', 'content': contains('Markdown')},
        for (var i = 4; i <= 12; i++)
          {'role': i.isEven ? 'assistant' : 'user', 'content': 'msg $i'},
        {'role': 'user', 'content': 'new question'},
      ],
      'word': 'A1',
    });
  });

  test('throws on empty message', () async {
    final chat = FakeChatRepository();
    final sessions = FakeChatSessionRepository();
    var calls = 0;
    final useCase = SendChatMessage(
      chat: chat,
      sessions: sessions,
      ai: AiClient(
        MockClient((_) async {
          calls++;
          return jsonResponse({'message': 'ok'}, 200);
        }),
      ),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    await expectLater(useCase('   '), throwsArgumentError);
    expect(chat.messages, isEmpty);
    expect(sessions.sessions, isEmpty);
    expect(calls, 0);
  });

  test('propagates AiException', () async {
    final chat = FakeChatRepository();
    final sessions = FakeChatSessionRepository();
    final useCase = SendChatMessage(
      chat: chat,
      sessions: sessions,
      ai: AiClient(MockClient((_) async => http.Response('boom', 500))),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    await expectLater(useCase('Привет'), throwsA(isA<AiException>()));
    // Сообщение пользователя сохранено до сети и переживает ошибку AI.
    expect(chat.messages.length, 1);
    expect(chat.messages.single.role, ChatRole.user);
    // Сессия создана до сети: начало диалога не теряется.
    expect(sessions.sessions, hasLength(1));
    expect(chat.messages.single.sessionId, sessions.sessions.single.id);
  });
}
