import 'dart:convert';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWithCounter(void Function() onRequest) =>
      ProviderContainer(
        overrides: [
          aiClientProvider.overrideWithValue(
            AiClient(
              MockClient((_) async {
                onRequest();
                return http.Response(
                  jsonEncode({'translation': 'Кот спит.'}),
                  200,
                  headers: const {
                    'content-type': 'application/json; charset=utf-8',
                  },
                );
              }),
            ),
          ),
        ],
      );

  test('should_request_once_when_same_sentence_read_twice', () async {
    var calls = 0;
    final container = containerWithCounter(() => calls++);
    addTearDown(container.dispose);

    const sentence = 'The cat sleeps.';
    final first = await container.read(
      sentenceTranslationProvider(sentence).future,
    );
    final second = await container.read(
      sentenceTranslationProvider(sentence).future,
    );

    expect(first, 'Кот спит.');
    expect(second, 'Кот спит.');
    expect(calls, 1);
  });

  test('should_request_per_sentence_when_sentences_differ', () async {
    var calls = 0;
    final container = containerWithCounter(() => calls++);
    addTearDown(container.dispose);

    await container.read(sentenceTranslationProvider('One.').future);
    await container.read(sentenceTranslationProvider('Two.').future);

    expect(calls, 2);
  });
}
