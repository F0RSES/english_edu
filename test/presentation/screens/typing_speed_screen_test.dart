import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/usecases/generate_typing_session.dart';
import 'package:english_edu/domain/usecases/save_typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/typing_speed_screen.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Widget host(TypingRecordRepository records) => ProviderScope(
  overrides: [
    generateTypingSessionProvider.overrideWithValue(
      GenerateTypingSession(
        words: FakeWordRepository([
          const Word(id: WordId(1), term: 'apple', translation: 'яблоко'),
        ]),
        settings: FakeSettingsRepository(),
        random: Random(1),
        wordsCount: 1,
      ),
    ),
    saveTypingRecordProvider.overrideWithValue(
      SaveTypingRecord(
        records: records,
        clock: () => DateTime.utc(2024, 5, 15, 12),
      ),
    ),
    bestTypingRecordProvider.overrideWith((ref) async => null),
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

    expect(find.text('Заезд завершён'), findsOneWidget);
    expect(records.saved, hasLength(1));
    expect(records.saved.single.correctCount, 1);
  });

  testWidgets('robot icon appears after a wrong answer', (tester) async {
    // Два слова: после неверного ответа заезд продолжается и карточка
    // остаётся на экране (с одним словом заезд завершился бы и карточка
    // исчезла вместе с полем ввода).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          generateTypingSessionProvider.overrideWithValue(
            GenerateTypingSession(
              words: FakeWordRepository([
                const Word(id: WordId(1), term: 'apple', translation: 'яблоко'),
                const Word(id: WordId(2), term: 'book', translation: 'книга'),
              ]),
              settings: FakeSettingsRepository(),
              random: Random(1),
              wordsCount: 2,
            ),
          ),
          saveTypingRecordProvider.overrideWithValue(
            SaveTypingRecord(
              records: _FakeRecords(),
              clock: () => DateTime.utc(2024, 5, 15, 12),
            ),
          ),
          bestTypingRecordProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: TypingSpeedScreen()),
      ),
    );
    await settleFrames(tester);

    expect(find.byType(ErrorHelperButton), findsNothing);

    await tester.enterText(find.byType(TextField), 'aple');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleFrames(tester);

    expect(find.byType(ErrorHelperButton), findsOneWidget);
  });

  testWidgets('renders without progress bar, best label and hint', (
    tester,
  ) async {
    await tester.pumpWidget(host(_FakeRecords()));
    await settleFrames(tester);

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Best:'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, isNull);
    // Живой WPM остаётся (ADR-037).
    expect(find.textContaining('WPM'), findsOneWidget);
  });
}
