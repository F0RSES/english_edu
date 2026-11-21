import 'dart:convert';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/word_example_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _word = Word(
  id: WordId(1),
  term: 'cat',
  translation: 'кот',
  exampleSentence: 'The cat sees cats.',
);

const _buttonKey = Key('translate-example-button');
const _sentenceKey = Key('example-sentence');
const _ru = 'Кот видит котов.';

http.Response jsonResponse(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

AiClient countingClient(void Function() onRequest) => AiClient(
  MockClient((_) async {
    onRequest();
    return jsonResponse({'translation': _ru}, 200);
  }),
);

Widget host({
  Word word = _word,
  String? exampleRu,
  AiClient? client,
  ThemeData? theme,
  AppLanguage lang = AppLanguage.ru,
}) => ProviderScope(
  overrides: [
    aiClientProvider.overrideWithValue(client ?? countingClient(() {})),
  ],
  child: MaterialApp(
    theme: theme,
    home: Scaffold(
      body: WordExampleSheet(word: word, exampleRu: exampleRu, lang: lang),
    ),
  ),
);

List<TextSpan> sentenceSpans(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byKey(_sentenceKey));
  final span = rich.text as TextSpan;
  return span.children!.whereType<TextSpan>().toList();
}

void main() {
  testWidgets('should_highlight_only_whole_word_when_rendered', (tester) async {
    await tester.pumpWidget(host());

    final highlighted = sentenceSpans(tester)
        .where((s) => s.style?.color == const Color(0xFF6750A4))
        .toList();
    expect(highlighted.length, 1);
    expect(highlighted.single.text, 'cat');
  });

  testWidgets('should_highlight_case_insensitively_when_word_capitalized', (
    tester,
  ) async {
    const word = Word(
      id: WordId(1),
      term: 'cat',
      translation: 'кот',
      exampleSentence: 'The Cat sleeps.',
    );
    await tester.pumpWidget(host(word: word));

    final highlighted = sentenceSpans(tester)
        .where((s) => s.style?.color == const Color(0xFF6750A4))
        .toList();
    expect(highlighted.single.text, 'Cat');
  });

  testWidgets('should_use_dark_highlight_when_theme_dark', (tester) async {
    await tester.pumpWidget(
      host(theme: ThemeData(brightness: Brightness.dark)),
    );

    final highlighted = sentenceSpans(tester)
        .where((s) => s.style?.color == const Color(0xFFD0BCFF))
        .toList();
    expect(highlighted.single.text, 'cat');
  });

  testWidgets('should_strip_en_prefix_when_present', (tester) async {
    const word = Word(
      id: WordId(1),
      term: 'cat',
      translation: 'кот',
      exampleSentence: 'EN: The cat sees cats.',
    );
    await tester.pumpWidget(host(word: word));

    final rich = tester.widget<RichText>(find.byKey(_sentenceKey));
    expect(rich.text.toPlainText(), 'The cat sees cats.');
  });

  testWidgets('should_show_translation_when_example_ru_present', (
    tester,
  ) async {
    await tester.pumpWidget(host(exampleRu: _ru));

    expect(find.text(_ru), findsOneWidget);
    expect(find.byKey(_buttonKey), findsNothing);
  });

  testWidgets('should_show_translate_button_when_example_ru_absent', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.byKey(_buttonKey), findsOneWidget);
    expect(find.text('Перевести'), findsOneWidget);
  });

  testWidgets('should_localize_button_when_lang_en', (tester) async {
    await tester.pumpWidget(host(lang: AppLanguage.en));

    expect(find.text('Translate'), findsOneWidget);
  });

  testWidgets('should_translate_when_button_pressed', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.byKey(_buttonKey));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text(_ru), findsOneWidget);
    expect(find.byKey(_buttonKey), findsNothing);
  });

  testWidgets('should_retry_after_error_when_button_pressed_again', (
    tester,
  ) async {
    var calls = 0;
    final client = AiClient(
      MockClient((_) async {
        calls++;
        return calls == 1
            ? jsonResponse({'error': 'fail'}, 500)
            : jsonResponse({'translation': _ru}, 200);
      }),
    );
    await tester.pumpWidget(host(client: client));

    await tester.tap(find.byKey(_buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось перевести'), findsOneWidget);
    expect(find.byKey(_buttonKey), findsOneWidget);

    await tester.tap(find.byKey(_buttonKey));
    await tester.pumpAndSettle();
    expect(find.text(_ru), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('should_show_cached_translation_when_reopened', (tester) async {
    var calls = 0;
    final container = ProviderContainer(
      overrides: [
        aiClientProvider.overrideWithValue(countingClient(() => calls++)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(
      sentenceTranslationProvider(_word.exampleSentence!).future,
    );
    expect(calls, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: WordExampleSheet(word: _word)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_ru), findsOneWidget);
    expect(find.byKey(_buttonKey), findsNothing);
    expect(calls, 1);
  });

  testWidgets('should_show_no_example_when_word_has_none', (tester) async {
    const word = Word(id: WordId(1), term: 'cat', translation: 'кот');
    await tester.pumpWidget(host(word: word));

    expect(find.text('Пример отсутствует'), findsOneWidget);
    expect(find.byKey(_buttonKey), findsNothing);
  });
}
