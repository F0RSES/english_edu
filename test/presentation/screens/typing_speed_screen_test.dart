import 'dart:convert';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/usecases/generate_typing_session.dart';
import 'package:english_edu/domain/usecases/save_typing_record.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/typing_speed_screen.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:english_edu/presentation/widgets/typing_results_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final class _FakeRecords implements TypingRecordRepository {
  final List<TypingRecord> saved = [];

  @override
  Future<TypingRecord?> getBest() async => null;

  @override
  Future<List<TypingRecord>> getTop({int limit = 10}) async => saved;

  @override
  Future<TypingRecord> save(TypingRecord record) async {
    saved.add(record);
    return record;
  }
}

const _twoWords = [
  Word(id: WordId(1), term: 'apple', translation: 'яблоко'),
  Word(id: WordId(2), term: 'book', translation: 'книга'),
];

/// Цвет рамки поля ввода (AnimatedContainer) для проверки фидбека.
Color fieldBorderColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  final decoration = container.decoration! as BoxDecoration;
  return decoration.border!.top.color;
}

Widget host(
  TypingRecordRepository records, {
  UserSettings? settings,
  List<Word>? words,
  int wordsCount = 1,
}) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(settings),
    ),
    generateTypingSessionProvider.overrideWithValue(
      GenerateTypingSession(
        words: FakeWordRepository(
          words ??
              [const Word(id: WordId(1), term: 'apple', translation: 'яблоко')],
        ),
        settings: FakeSettingsRepository(),
        random: Random(1),
        wordsCount: wordsCount,
      ),
    ),
    saveTypingRecordProvider.overrideWithValue(
      SaveTypingRecord(
        records: records,
        clock: () => DateTime.utc(2024, 5, 15, 12),
      ),
    ),
    bestTypingRecordProvider.overrideWith((ref) async => null),
    clockProvider.overrideWithValue(() => DateTime.utc(2024, 5, 15, 12)),
    aiClientProvider.overrideWithValue(
      AiClient(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'explanation': 'объяснение'}),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    ),
  ],
  child: const MaterialApp(home: TypingSpeedScreen()),
);

/// Кадры вместо `pumpAndSettle`: экран держит `Timer.periodic`, и settle
/// не дождётся тишины.
Future<void> settleFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('renders translation and input', (tester) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    expect(find.text('яблоко'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('correct answer finishes the session', (tester) async {
    final records = _FakeRecords();
    await tester.pumpWidget(host(records));
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(find.byType(TypingResultsSheet), findsOneWidget);
    expect(records.saved, hasLength(1));
    expect(records.saved.single.correctCount, 1);
  });

  testWidgets('should_not_show_helper_or_incorrect_plate_during_game', (
    tester,
  ) async {
    // Два слова: после неверного ответа заезд продолжается, поле на экране.
    await tester.pumpWidget(
      host(_FakeRecords(), wordsCount: 2, words: _twoWords),
    );
    await settleFrames(tester);

    expect(find.byType(ErrorHelperButton), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    // Блиц: помощник и плашка «Неверно» не появляются во время ввода.
    expect(find.byType(ErrorHelperButton), findsNothing);
    expect(find.text('Неверно'), findsNothing);
  });

  testWidgets('renders without progress bar, best label, hint and WPM', (
    tester,
  ) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Best:'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, isNull);
    // Блиц: WPM-счётчик убран из верхней панели (Phase 55a).
    expect(find.textContaining('WPM'), findsNothing);
  });

  testWidgets('app bar title is Russian by default', (tester) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    expect(find.text('Скорость печати'), findsOneWidget);
  });

  testWidgets('switches to EN labels when lang=en', (tester) async {
    await tester.pumpWidget(
      host(
        _FakeRecords(),
        settings: const UserSettings(language: AppLanguage.en),
      ),
    );
    await settleFrames(tester);

    expect(find.text('Typing Speed'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('no SnackBar after correct answer', (tester) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('should_not_show_letter_hint', (tester) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    // Блиц: подсказка длины/первой буквы убрана (Phase 55a).
    expect(find.text('5 букв, a...'), findsNothing);
    expect(find.textContaining('букв'), findsNothing);
  });

  testWidgets('accepts a synonym as the correct answer', (tester) async {
    final records = _FakeRecords();
    await tester.pumpWidget(
      host(
        records,
        words: [
          const Word(
            id: WordId(1),
            term: 'meal',
            translation: 'еда',
            synonyms: ['food'],
          ),
        ],
      ),
    );
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'food');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(find.byType(TypingResultsSheet), findsOneWidget);
    expect(records.saved.single.correctCount, 1);
  });

  testWidgets('should_show_timer_and_progress_chips', (tester) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    expect(find.textContaining('WPM'), findsNothing);
  });

  testWidgets('should_color_border_green_on_correct_answer', (tester) async {
    await tester.pumpWidget(
      host(_FakeRecords(), wordsCount: 2, words: _twoWords),
    );
    await settleFrames(tester);

    final isApple = find.text('яблоко').evaluate().isNotEmpty;
    await tester.enterText(find.byType(TextField), isApple ? 'apple' : 'book');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(fieldBorderColor(tester), Colors.green);
  });

  testWidgets('should_color_border_red_on_wrong_answer', (tester) async {
    await tester.pumpWidget(
      host(_FakeRecords(), wordsCount: 2, words: _twoWords),
    );
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(fieldBorderColor(tester), Colors.redAccent);
    expect(find.text('Неверно'), findsNothing);
  });

  testWidgets('should_open_results_sheet_with_rows_on_finish', (tester) async {
    await tester.pumpWidget(
      host(_FakeRecords(), wordsCount: 2, words: _twoWords),
    );
    await settleFrames(tester);

    // Отвечаем на оба слова (одно верно, одно неверно) — заезд завершается.
    final isApple = find.text('яблоко').evaluate().isNotEmpty;
    await tester.enterText(find.byType(TextField), isApple ? 'apple' : 'book');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(find.byType(TypingResultsSheet), findsOneWidget);
    expect(find.text('Результаты'), findsOneWidget);
    expect(find.byKey(const Key('results-filter')), findsOneWidget);
    expect(find.byKey(const Key('results-again')), findsOneWidget);
    expect(find.byKey(const Key('results-close')), findsOneWidget);
    expect(find.byType(ErrorHelperButton), findsNWidgets(2));
    expect(find.byIcon(Icons.bookmark_add_outlined), findsNWidgets(2));
  });
}
