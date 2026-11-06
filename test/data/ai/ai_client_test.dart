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
}
