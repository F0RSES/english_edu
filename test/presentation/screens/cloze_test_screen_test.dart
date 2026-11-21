import 'dart:convert';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/theme/app_colors.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/usecases/get_cloze_task.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/cloze_test_screen.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:english_edu/presentation/widgets/bulk_dictionary_sheet.dart';
import 'package:english_edu/presentation/widgets/sentence_analysis_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_app_meta_repository.dart';
import '../../domain/usecases/fakes/fake_cloze_generator.dart';
import '../../domain/usecases/fakes/fake_cloze_task_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_translation_generator.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

final _task = ClozeTask(
  sentence: 'I ___ apples every day.',
  correctWord: 'eat',
  options: const ['eat', 'eats', 'ate', 'eating', 'eaten'],
);

/// Экран с фейками: словарь из одного слова, задание — из генератора.
Widget host({
  FakeClozeGenerator? generator,
  FakeClozeTaskRepository? tasks,
  List<Word> words = const [],
  UserSettings? settings,
  Widget? home,
  FakeProgressRepository? progress,
  Random? random,
}) {
  final settingsRepository = FakeSettingsRepository(settings);
  return ProviderScope(
    overrides: [
      progressRepositoryProvider.overrideWithValue(
        progress ?? FakeProgressRepository(),
      ),
      appMetaRepositoryProvider.overrideWithValue(FakeAppMetaRepository()),
      clockProvider.overrideWithValue(() => now),
      wordRepositoryProvider.overrideWithValue(
        FakeWordRepository(
          words.isEmpty
              ? const [Word(id: WordId(1), term: 'eat', translation: 'есть')]
              : words,
        ),
      ),
      getClozeTaskProvider.overrideWithValue(
        GetClozeTask(
          tasks: tasks ?? FakeClozeTaskRepository(),
          generator: generator ?? FakeClozeGenerator(task: _task),
          settings: settingsRepository,
          clock: () => now,
        ),
      ),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      translationGeneratorProvider.overrideWithValue(
        FakeTranslationGenerator(),
      ),
      aiClientProvider.overrideWithValue(
        AiClient(
          MockClient(
            (_) async => http.Response(
              jsonEncode({'translation': 'перевод', 'tense': 'Present Simple'}),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8',
              },
            ),
          ),
        ),
      ),
    ],
    child: MaterialApp(home: home ?? ClozeTestScreen(random: random)),
  );
}

/// Порядок вариантов ответа Cloze, как они отрендерены (сверху вниз).
List<String> renderedOptionOrder(WidgetTester tester) {
  const options = ['eat', 'eats', 'ate', 'eating', 'eaten'];
  final entries = [
    for (final option in options)
      (
        option: option,
        dy: tester.getTopLeft(find.byKey(ValueKey('option-$option'))).dy,
      ),
  ]..sort((a, b) => a.dy.compareTo(b.dy));
  return [for (final entry in entries) entry.option];
}

/// Тапает вариант ответа, доскроллировав до него: порядок перемешан (54a),
/// и на тестовом экране пятый вариант может быть за пределами ListView.
Future<void> tapOption(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets('renders sentence and five options', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text(_task.sentence), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    for (final option in _task.options) {
      expect(find.text(option), findsOneWidget);
    }
  });

  testWidgets('tapping correct option shows success', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.text('Следующее задание'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tapping wrong option shows error then resets', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eats'));
    await tester.pump();

    // Красная карточка варианта + раскрытое слово с ботом (Phase 30b).
    expect(find.byType(AiWordHelper), findsOneWidget);
    final context = tester.element(find.text('eats'));
    final expected = Theme.of(context).colorScheme.errorContainer;
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('eats'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, expected);

    // Через 500 мс карточка сброшена — можно выбрать другую.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // После раскрытия слова 'eat' есть и в helper, и в варианте: тапаем
    // именно карточку варианта по ключу.
    await tapOption(tester, find.byKey(const ValueKey('option-eat')));
    await tester.pumpAndSettle();

    expect(find.text('Следующее задание'), findsOneWidget);
  });

  testWidgets('shows error state with retry when the task fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(generator: FakeClozeGenerator(error: Exception('offline'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('serves the second task from the cache', (tester) async {
    final generator = FakeClozeGenerator(task: _task);
    final tasks = FakeClozeTaskRepository();

    await tester.pumpWidget(host(generator: generator, tasks: tasks));
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Следующее задание'));
    await tester.pumpAndSettle();

    expect(generator.calls, 1);
    expect(find.text(_task.sentence), findsOneWidget);
  });

  testWidgets('word helper appears only after a wrong answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(AiWordHelper), findsNothing);

    await tapOption(tester, find.text('eats'));
    await tester.pumpAndSettle();

    expect(find.byType(AiWordHelper), findsOneWidget);
  });

  testWidgets('shows parse-sentence button before and after answer', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Разобрать предложение'), findsOneWidget);

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.text('Разобрать предложение'), findsOneWidget);
  });

  testWidgets('shows helper after answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();

    final helper = tester.widget<AiWordHelper>(find.byType(AiWordHelper));
    expect(helper.revealWord, isTrue);
    expect(helper.word, 'eat');
    expect(helper.iconSize, 16);
  });

  testWidgets('uses only preferredLevel words', (tester) async {
    final generator = FakeClozeGenerator(task: _task);
    await tester.pumpWidget(
      host(
        generator: generator,
        words: const [
          Word(id: WordId(1), term: 'eat', translation: 'есть'),
          Word(
            id: WordId(2),
            term: 'facility',
            translation: 'учреждение',
            level: CefrLevel.b1,
          ),
        ],
        settings: const UserSettings(),
      ),
    );
    await tester.pumpAndSettle();

    expect(generator.words, ['eat']);
  });

  testWidgets('app bar title is Russian by default', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Заполни пропуск'), findsOneWidget);
  });

  testWidgets('switches to EN labels when lang=en', (tester) async {
    await tester.pumpWidget(
      host(settings: const UserSettings(language: AppLanguage.en)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gap fill'), findsOneWidget);
    expect(find.text('Parse sentence'), findsOneWidget);

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();
    expect(find.text('Next task'), findsOneWidget);
  });

  testWidgets('no SnackBar after correct answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Следующее задание'), findsOneWidget);
  });

  testWidgets('pulse animation on correct option', (tester) async {
    // Высокий экран: все варианты и кнопка «Далее» помещаются без скролла,
    // correct-карточка не удаляется ListView после ответа (Phase 54a).
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('option-eat')),
        matching: find.byType(Animate),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dispose hides SnackBar on exit', (tester) async {
    await tester.pumpWidget(
      host(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ClozeTestScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(tester.element(find.byType(ClozeTestScreen)))
        .showSnackBar(const SnackBar(content: Text('service')));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);

    Navigator.of(tester.element(find.byType(ClozeTestScreen))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('add-to-dictionary opens bulk sheet with five words', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cloze-bulk-words')));
    await tester.pumpAndSettle();

    expect(find.byType(BulkDictionarySheet), findsOneWidget);
    expect(find.byKey(const Key('app-bottom-sheet-handle')), findsOneWidget);
    expect(find.text('Слова в задании'), findsOneWidget);
    for (final option in _task.options) {
      expect(
        find.descendant(
          of: find.byType(BulkDictionarySheet),
          matching: find.text(option),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('should_show_plus_for_seed_word_in_bulk_sheet', (tester) async {
    // 'eat' — seed-слово в БД без прогресса: в листе «+», не корзина
    // (Phase 52b: наличие в БД не значит «Изучаю»).
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cloze-bulk-words')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BulkDictionarySheet),
        matching: find.byIcon(Icons.add_circle_outline),
      ),
      findsNWidgets(5),
    );
    expect(
      find.descendant(
        of: find.byType(BulkDictionarySheet),
        matching: find.byIcon(Icons.delete_outline),
      ),
      findsNothing,
    );
  });

  testWidgets('should_show_trash_for_learning_word_in_bulk_sheet', (
    tester,
  ) async {
    final progress = FakeProgressRepository([
      WordProgress(
        wordId: const WordId(1),
        cardState: CardState.initial(now),
        status: WordStatus.learning,
        firstSeenAt: now,
      ),
    ]);
    await tester.pumpWidget(host(progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cloze-bulk-words')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BulkDictionarySheet),
        matching: find.byIcon(Icons.delete_outline),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BulkDictionarySheet),
        matching: find.byIcon(Icons.add_circle_outline),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('should_add_to_learning_from_bulk_sheet', (tester) async {
    final progress = FakeProgressRepository();
    await tester.pumpWidget(host(progress: progress));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cloze-bulk-words')));
    await tester.pumpAndSettle();
    // Варианты перемешаны (54a): тапаем «+» именно в строке 'eat'.
    final eatRow = find.ancestor(
      of: find.descendant(
        of: find.byType(BulkDictionarySheet),
        matching: find.text('eat'),
      ),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(
        of: eatRow,
        matching: find.byIcon(Icons.add_circle_outline),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      (await progress.getByWordId(const WordId(1)))?.status,
      WordStatus.learning,
    );
    expect(find.text('Слово добавлено в «Изучаю»'), findsOneWidget);
  });

  testWidgets('should_shuffle_options_when_task_loaded', (tester) async {
    // Seed 7 детерминированно даёт [eats, eating, eat, eaten, ate]:
    // correctWord не первый, порядок отличается от порядка прокси.
    await tester.pumpWidget(host(random: Random(7)));
    await tester.pumpAndSettle();

    final order = renderedOptionOrder(tester);
    expect(order, ['eats', 'eating', 'eat', 'eaten', 'ate']);
    expect(order.first, isNot('eat'));
  });

  testWidgets('should_accept_correct_answer_at_any_position', (tester) async {
    // correctWord последний в списке прокси: проверка по тексту, не индексу.
    final task = ClozeTask(
      sentence: 'I ___ apples every day.',
      correctWord: 'eat',
      options: const ['eats', 'ate', 'eating', 'eaten', 'eat'],
    );
    await tester.pumpWidget(host(generator: FakeClozeGenerator(task: task)));
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.text('Следующее задание'), findsOneWidget);
  });

  testWidgets('should_highlight_correct_option_purple_when_answered', (
    tester,
  ) async {
    // Высокий экран: correct-карточка не удаляется ListView после ответа.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapOption(tester, find.text('eat'));
    await tester.pump();

    // Фон correct-карточки — бледно-фиолетовый акцент (Phase 54b).
    final card = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('option-eat')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(card.color, AppColors.accentPurpleLight.withValues(alpha: 0.2));

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('should_open_sentence_analysis_when_parse_button_tapped', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Разобрать предложение'));
    await tester.pumpAndSettle();

    expect(find.byType(SentenceAnalysisSheet), findsOneWidget);
    expect(find.byKey(const Key('app-bottom-sheet-handle')), findsOneWidget);
  });
}
