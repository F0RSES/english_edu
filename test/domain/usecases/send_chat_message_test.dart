import 'dart:convert';

import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/usecases/send_chat_message.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fakes/fake_chat_repository.dart';
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
    final useCase = SendChatMessage(
      chat: chat,
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
        {'role': 'user', 'content': 'Привет'},
      ],
      'word': 'A1',
    });
  });

  test('limits context to last 10 messages', () async {
    Object? capturedBody;
    final initial = [
      for (var i = 1; i <= 12; i++)
        ChatMessage(
          id: i,
          role: i.isEven ? ChatRole.assistant : ChatRole.user,
          content: 'msg $i',
          createdAtUtc: _now.add(Duration(minutes: i)),
        ),
    ];
    final chat = FakeChatRepository(initial);
    final useCase = SendChatMessage(
      chat: chat,
      ai: AiClient(
        MockClient((request) async {
          capturedBody = jsonDecode(request.body);
          return jsonResponse({'message': 'ok'}, 200);
        }),
      ),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    await useCase('new question');

    // 12 старых + 1 новое = 13; в контекст уходят последние 10:
    // msg 4…12 плюс новое.
    expect(capturedBody, {
      'type': 'chat',
      'messages': [
        for (var i = 4; i <= 12; i++)
          {'role': i.isEven ? 'assistant' : 'user', 'content': 'msg $i'},
        {'role': 'user', 'content': 'new question'},
      ],
      'word': 'A1',
    });
  });

  test('throws on empty message', () async {
    final chat = FakeChatRepository();
    var calls = 0;
    final useCase = SendChatMessage(
      chat: chat,
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
    expect(calls, 0);
  });

  test('propagates AiException', () async {
    final chat = FakeChatRepository();
    final useCase = SendChatMessage(
      chat: chat,
      ai: AiClient(MockClient((_) async => http.Response('boom', 500))),
      settings: FakeSettingsRepository(),
      clock: () => _now,
    );

    await expectLater(useCase('Привет'), throwsA(isA<AiException>()));
    // Сообщение пользователя сохранено до сети и переживает ошибку AI.
    expect(chat.messages.length, 1);
    expect(chat.messages.single.role, ChatRole.user);
  });
}
