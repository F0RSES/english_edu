import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_dictation_queue.dart';
import 'package:english_edu/domain/usecases/record_review.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/listening_dictation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fakes/fake_crash_reporter.dart';
import '../../core/tts/fake_tts_service.dart';
import '../../domain/usecases/fakes/fake_frozen_days_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_review_log_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_srs_calculator.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

Word word(int id, String term, {String? transcription}) => Word(
  id: WordId(id),
  term: term,
  translation: 'перевод$term',
  transcription: transcription,
);

/// Окружение диктанта: словарь, TTS-шпион и настоящий `RecordReview`.
final class Harness {
  Harness({List<Word>? words, FakeWordRepository? wordRepo, int seed = 3})
    : wordRepo = wordRepo ?? FakeWordRepository(words ?? [word(1, 'apple')]),
      tts = FakeTtsService() {
    queue = GenerateDictationQueue(words: this.wordRepo, random: Random(seed));
  }

  final FakeWordRepository wordRepo;
  final FakeTtsService tts;
  final FakeProgressRepository progress = FakeProgressRepository();
  final FakeReviewLogRepository logs = FakeReviewLogRepository();
  final FakeStatsRepository stats = FakeStatsRepository();
  final FakeSettingsRepository settings = FakeSettingsRepository(
    UserSettings.defaults().copyWith(ttsVoice: 'en-GB', ttsSpeed: 0.6),
  );
  final FakeCrashReporter crashReporter = FakeCrashReporter();
  late final GenerateDictationQueue queue;
  var _nextId = 1;

  Widget app() => ProviderScope(
    overrides: [
      wordRepositoryProvider.overrideWithValue(wordRepo),
      generateDictationQueueProvider.overrideWithValue(queue),
      ttsProvider.overrideWithValue(tts),
      settingsRepositoryProvider.overrideWithValue(settings),
      statsRepositoryProvider.overrideWithValue(stats),
      frozenDaysRepositoryProvider.overrideWithValue(
        FakeFrozenDaysRepository(),
      ),
      crashReporterProvider.overrideWithValue(crashReporter),
      clockProvider.overrideWithValue(() => now),
      recordReviewProvider.overrideWithValue(
        RecordReview(
          progress: progress,
          reviewLog: logs,
          stats: stats,
          words: wordRepo,
          srs: const FakeSrsCalculator(),
          nextLogId: () => ReviewLogId(_nextId++),
          clock: () => now,
        ),
      ),
    ],
    child: const MaterialApp(home: ListeningDictationScreen()),
  );
}

Future<void> typeAndCheck(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text('Проверить'));
  await tester.pump();
}

void main() {
  testWidgets('renders loading state', (tester) async {
    final pending = Completer<void>();
    final repo = FakeWordRepository([word(1, 'apple')])
      ..beforeGetAll = () => pending.future;

    await tester.pumpWidget(Harness(wordRepo: repo).app());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Введите слово...'), findsNothing);

    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('speaks word via TTS on load', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    // Настройки из UserSettings, а не дефолты плагина.
    expect(harness.tts.lastText, 'apple');
    expect(harness.tts.lastVoice, 'en-GB');
    expect(harness.tts.lastSpeed, 0.6);
  });

  testWidgets('tap speaker speaks again', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    expect(harness.tts.speakCount, 1);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(harness.tts.speakCount, 2);
  });

  testWidgets('correct answer shows success', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await typeAndCheck(tester, 'Apple');

    expect(find.text('Правильно!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('wrong answer reveals correct word', (tester) async {
    final harness = Harness(words: [word(1, 'apple', transcription: '/ˈæpl/')]);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await typeAndCheck(tester, 'aple');

    expect(find.text('Неверно'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('/ˈæpl/'), findsOneWidget);
    expect(find.text('Следующее слово'), findsOneWidget);

    // Доанимация раскрытого ответа: иначе остаётся pending timer.
    await tester.pumpAndSettle();
  });

  testWidgets('correct answer records SRS good grade', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await typeAndCheck(tester, 'apple');
    await tester.pump();

    final log = (await harness.logs.getAll()).single;
    expect(log.grade, ReviewGrade.good);
    expect(log.wordId, const WordId(1));

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('wrong answer records SRS again grade', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await typeAndCheck(tester, 'nope');
    await tester.pump();

    final log = (await harness.logs.getAll()).single;
    expect(log.grade, ReviewGrade.again);

    await tester.pumpAndSettle();
  });

  testWidgets('advances to next word after success', (tester) async {
    final harness = Harness(words: [word(1, 'apple'), word(2, 'book')]);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    final first = harness.tts.lastText;
    await typeAndCheck(tester, first ?? 'apple');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('2/2'), findsOneWidget);
    // Следующее слово читается само.
    expect(harness.tts.lastText, isNot(first));
  });

  testWidgets('does not record twice for the same word', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await typeAndCheck(tester, 'apple');
    await tester.pump();
    // Повторный Enter по тому же слову не должен перезаписать прогресс.
    await tester.tap(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(await harness.logs.getAll(), hasLength(1));

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('session complete shows dialog', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await typeAndCheck(tester, 'apple');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.text('Верно: 1 из 1'), findsOneWidget);
  });
}
