import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/get_cloze_task.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/cloze_test_screen.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:english_edu/presentation/widgets/bulk_dictionary_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_cloze_generator.dart';
import '../../domain/usecases/fakes/fake_cloze_task_repository.dart';
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
}) {
  final settingsRepository = FakeSettingsRepository(settings);
  return ProviderScope(
    overrides: [
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
    ],
    child: MaterialApp(home: home ?? const ClozeTestScreen()),
  );
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

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.text('Следующее задание'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tapping wrong option shows error then resets', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('eats'));
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
    await tester.tap(find.byKey(const ValueKey('option-eat')));
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

    await tester.tap(find.text('eat'));
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

    await tester.tap(find.text('eats'));
    await tester.pumpAndSettle();

    expect(find.byType(AiWordHelper), findsOneWidget);
  });

  testWidgets('shows add-to-dictionary button before and after answer', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Разобрать слово'), findsOneWidget);

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.text('Разобрать слово'), findsOneWidget);
  });

  testWidgets('shows helper after answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('eat'));
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
    expect(find.text('Parse word'), findsOneWidget);

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();
    expect(find.text('Next task'), findsOneWidget);
  });

  testWidgets('no SnackBar after correct answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Следующее задание'), findsOneWidget);
  });

  testWidgets('pulse animation on correct option', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('eat'));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(of: find.text('eat'), matching: find.byType(Animate)),
      findsWidgets,
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
                  MaterialPageRoute<void>(
                    builder: (_) => const ClozeTestScreen(),
                  ),
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

    await tester.tap(find.text('Разобрать слово'));
    await tester.pumpAndSettle();

    expect(find.byType(BulkDictionarySheet), findsOneWidget);
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
}
