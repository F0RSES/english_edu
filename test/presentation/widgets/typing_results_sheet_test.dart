import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_result.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:english_edu/presentation/widgets/typing_results_sheet.dart';
import 'package:english_edu/presentation/widgets/word_example_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_app_meta_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

const _apple = Word(
  id: WordId(1),
  term: 'apple',
  translation: 'яблоко',
  exampleSentence: 'I eat an apple.',
);
const _book = Word(
  id: WordId(2),
  term: 'book',
  translation: 'книга',
  exampleSentence: 'Read a book.',
);

final _t0 = DateTime.utc(2026, 11, 21, 12);

final _record = TypingRecord(
  id: 1,
  wordsCount: 2,
  correctCount: 1,
  durationSeconds: 45,
  wpm: 40,
  accuracyPercent: 50,
  score: 100,
  createdAtUtc: _t0,
);

TypingResult _result(Word word, String input, bool correct, int second) =>
    TypingResult(
      word: word,
      userInput: input,
      isCorrect: correct,
      timestamp: _t0.add(Duration(seconds: second)),
    );

Widget _scope(Widget child) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    aiClientProvider.overrideWithValue(
      AiClient(
        MockClient(
          (_) async => http.Response(
            '{"explanation":"x"}',
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    ),
    wordRepositoryProvider.overrideWithValue(
      FakeWordRepository([_apple, _book]),
    ),
    progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
    appMetaRepositoryProvider.overrideWithValue(FakeAppMetaRepository()),
    clockProvider.overrideWithValue(() => _t0),
  ],
  child: child,
);

Widget host(List<TypingResult> results) => _scope(
  MaterialApp(
    home: Scaffold(
      body: TypingResultsSheet(results: results, record: _record),
    ),
  ),
);

/// Вертикальная позиция ввода слова — для проверки порядка строк.
double inputDy(WidgetTester tester, String word) =>
    tester.getTopLeft(find.byKey(Key('result-input-$word'))).dy;

void main() {
  testWidgets('should_render_rows_and_summary', (tester) async {
    await tester.pumpWidget(
      host([
        _result(_apple, 'apple', true, 0),
        _result(_book, 'bok', false, 1),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Результаты'), findsOneWidget);
    expect(find.text('50% · 40 WPM · 0:45'), findsOneWidget);
    expect(find.text('bok'), findsOneWidget);
    expect(find.text('book'), findsOneWidget);
  });

  testWidgets('should_show_ai_and_dictionary_buttons', (tester) async {
    await tester.pumpWidget(
      host([
        _result(_apple, 'apple', true, 0),
        _result(_book, 'bok', false, 1),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorHelperButton), findsNWidgets(2));
    expect(find.byIcon(Icons.bookmark_add_outlined), findsNWidgets(2));
  });

  testWidgets('should_sort_correct_first_when_filter_selected', (tester) async {
    await tester.pumpWidget(
      host([
        _result(_book, 'bok', false, 0),
        _result(_apple, 'apple', true, 1),
      ]),
    );
    await tester.pumpAndSettle();

    // По очереди: неверный book (t0) раньше верного apple (t1).
    expect(inputDy(tester, 'book'), lessThan(inputDy(tester, 'apple')));

    await tester.tap(find.byKey(const Key('results-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сначала правильные').last);
    await tester.pumpAndSettle();

    expect(inputDy(tester, 'apple'), lessThan(inputDy(tester, 'book')));
  });

  testWidgets('should_sort_wrong_first_when_filter_selected', (tester) async {
    await tester.pumpWidget(
      host([
        _result(_apple, 'apple', true, 0),
        _result(_book, 'bok', false, 1),
      ]),
    );
    await tester.pumpAndSettle();

    expect(inputDy(tester, 'apple'), lessThan(inputDy(tester, 'book')));

    await tester.tap(find.byKey(const Key('results-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сначала неправильные').last);
    await tester.pumpAndSettle();

    expect(inputDy(tester, 'book'), lessThan(inputDy(tester, 'apple')));
  });

  testWidgets('should_open_word_example_sheet_when_dictionary_tapped', (
    tester,
  ) async {
    await tester.pumpWidget(host([_result(_apple, 'apple', true, 0)]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('result-dictionary-apple')));
    await tester.pumpAndSettle();

    expect(find.byType(WordExampleSheet), findsOneWidget);
    expect(find.byKey(const Key('example-status-button')), findsOneWidget);
  });

  testWidgets('should_return_true_when_again_pressed', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _scope(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await TypingResultsSheet.show(
                    context,
                    results: [_result(_apple, 'apple', true, 0)],
                    record: _record,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('results-again')));
    await tester.pumpAndSettle();

    expect(result, true);
  });

  testWidgets('should_return_false_when_close_pressed', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _scope(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await TypingResultsSheet.show(
                    context,
                    results: [_result(_apple, 'apple', true, 0)],
                    record: _record,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('results-close')));
    await tester.pumpAndSettle();

    expect(result, false);
  });
}
