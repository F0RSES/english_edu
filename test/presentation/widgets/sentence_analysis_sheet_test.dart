import 'dart:async';
import 'dart:convert';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/presentation/widgets/sentence_analysis_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _sentence = 'I ___ apples every day.';
const _word = 'eat';
const _translation = 'Я ем яблоки каждый день.';
const _tense = 'Present Simple';

http.Response jsonResponse(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);

AiClient okClient() => AiClient(
  MockClient(
    (_) async =>
        jsonResponse({'translation': _translation, 'tense': _tense}, 200),
  ),
);

Widget host({AiClient? client}) => ProviderScope(
  overrides: [aiClientProvider.overrideWithValue(client ?? okClient())],
  child: const MaterialApp(
    home: Scaffold(
      body: SentenceAnalysisSheet(sentence: _sentence, correctWord: _word),
    ),
  ),
);

List<TextSpan> sentenceSpans(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.byKey(const Key('analysis-sentence')),
  );
  final span = rich.text as TextSpan;
  return span.children!.whereType<TextSpan>().toList();
}

void main() {
  testWidgets('should_render_restored_sentence_with_highlighted_word', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final rich = tester.widget<RichText>(
      find.byKey(const Key('analysis-sentence')),
    );
    expect(rich.text.toPlainText(), 'I eat apples every day.');
    final highlighted = sentenceSpans(tester)
        .where((s) => s.style?.color == AppColors.accentPurpleLight)
        .toList();
    expect(highlighted.single.text, 'eat');
  });

  testWidgets('should_render_translation_and_tense_chip', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text(_translation), findsOneWidget);
    expect(find.text(_tense), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('should_show_loader_while_request_pending', (tester) async {
    final completer = Completer<http.Response>();
    final client = AiClient(MockClient((_) => completer.future));
    await tester.pumpWidget(host(client: client));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      jsonResponse({'translation': _translation, 'tense': _tense}, 200),
    );
    await tester.pumpAndSettle();
    expect(find.text(_tense), findsOneWidget);
  });

  testWidgets('should_show_error_and_retry_when_request_fails', (tester) async {
    var calls = 0;
    final client = AiClient(
      MockClient((_) async {
        calls++;
        return calls == 1
            ? jsonResponse({'error': 'fail'}, 500)
            : jsonResponse({'translation': _translation, 'tense': _tense}, 200);
      }),
    );
    await tester.pumpWidget(host(client: client));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось перевести'), findsOneWidget);
    expect(find.byKey(const Key('analysis-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('analysis-retry')));
    await tester.pumpAndSettle();

    expect(find.text(_tense), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('should_open_in_app_bottom_sheet_when_show_called', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiClientProvider.overrideWithValue(okClient())],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SentenceAnalysisSheet.show(
                  context,
                  sentence: _sentence,
                  correctWord: _word,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SentenceAnalysisSheet), findsOneWidget);
    expect(find.byKey(const Key('app-bottom-sheet-handle')), findsOneWidget);
  });
}
