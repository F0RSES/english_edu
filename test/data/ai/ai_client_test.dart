import 'dart:convert';

import 'package:english_edu/data/ai/ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Ответ прокси: JSON с явным UTF-8.
///
/// Без charset `http.Response` кодирует тело в latin1 и кириллица падает ещё
/// до клиента — это ограничение тестового двойника, а не продакшн-кода.
http.Response jsonResponse(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('returns the association and posts the word to the proxy', () async {
    Uri? capturedUrl;
    Object? capturedBody;
    final client = AiClient(
      MockClient((request) async {
        capturedUrl = request.url;
        capturedBody = jsonDecode(request.body);
        return jsonResponse({'association': 'представь приветствие'}, 200);
      }),
    );

    final association = await client.generate('hello');

    expect(association, 'представь приветствие');
    expect(
      capturedUrl.toString(),
      'https://english-edu-ai.forses17.workers.dev/',
    );
    expect(capturedBody, {'word': 'hello'});
  });

  test('throws AiException with the status on a server error', () async {
    final client = AiClient(
      MockClient((_) async => http.Response('boom', 500)),
    );

    await expectLater(
      client.generate('hello'),
      throwsA(
        isA<AiException>().having((error) => error.statusCode, 'status', 500),
      ),
    );
  });

  test('throws AiException when the payload has no association', () async {
    final client = AiClient(
      MockClient((_) async => jsonResponse({'oops': true}, 200)),
    );

    await expectLater(client.generate('hello'), throwsA(isA<AiException>()));
  });

  test('throws AiException on invalid JSON', () async {
    final client = AiClient(
      MockClient((_) async => http.Response('not json', 200)),
    );

    await expectLater(client.generate('hello'), throwsA(isA<AiException>()));
  });

  test('generateCloze parses JSON and posts the cloze type', () async {
    Object? capturedBody;
    final client = AiClient(
      MockClient((request) async {
        capturedBody = jsonDecode(request.body);
        return jsonResponse({
          'sentence': 'I ___ apples every day.',
          'answer': 'eat',
        }, 200);
      }),
    );

    final task = await client.generateCloze('eat');

    expect(capturedBody, {'type': 'cloze_test', 'word': 'eat'});
    expect(task.sentence, 'I ___ apples every day.');
    expect(task.answer, 'eat');
  });

  test('generateCloze throws on a malformed payload', () async {
    final client = AiClient(
      MockClient((_) async => jsonResponse({'sentence': 'no answer'}, 200)),
    );

    await expectLater(client.generateCloze('eat'), throwsA(isA<AiException>()));
  });

  test('sendChat posts the chat type, messages and level', () async {
    Object? capturedBody;
    final client = AiClient(
      MockClient((request) async {
        capturedBody = jsonDecode(request.body);
        return jsonResponse({'message': 'Привет! Чем помочь?'}, 200);
      }),
    );

    final reply = await client.sendChat(
      messages: const [
        (role: 'user', content: 'Привет'),
        (role: 'assistant', content: 'Здравствуйте!'),
      ],
      level: 'A2',
    );

    expect(reply, 'Привет! Чем помочь?');
    expect(capturedBody, {
      'type': 'chat',
      'messages': [
        {'role': 'user', 'content': 'Привет'},
        {'role': 'assistant', 'content': 'Здравствуйте!'},
      ],
      'word': 'A2',
    });
  });

  test('sendChat throws AiException when the payload has no message', () async {
    final client = AiClient(
      MockClient((_) async => jsonResponse({'oops': true}, 200)),
    );

    await expectLater(
      client.sendChat(
        messages: const [(role: 'user', content: 'hi')],
        level: 'A1',
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('explain() posts correct payload', () async {
    Object? capturedBody;
    final client = AiClient(
      MockClient((request) async {
        capturedBody = jsonDecode(request.body);
        return jsonResponse({
          'explanation': 'Глагол go в Past Simple — went.',
        }, 200);
      }),
    );

    await client.explain(
      gameType: 'cloze_test',
      context: 'Игра: cloze_test. Ошибка.',
    );

    expect(capturedBody, {
      'type': 'explain_error',
      'word': 'Игра: cloze_test. Ошибка.',
    });
  });

  test('explain() parses response', () async {
    final client = AiClient(
      MockClient(
        (_) async => jsonResponse({'explanation': 'Объяснение ошибки'}, 200),
      ),
    );

    final result = await client.explain(
      gameType: 'typing',
      context: 'контекст',
    );

    expect(result, 'Объяснение ошибки');
  });

  test('explain() throws AiException on 500', () async {
    final client = AiClient(
      MockClient((_) async => http.Response('boom', 500)),
    );

    await expectLater(
      client.explain(gameType: 'listening', context: 'контекст'),
      throwsA(isA<AiException>().having((e) => e.statusCode, 'status', 500)),
    );
  });
}
