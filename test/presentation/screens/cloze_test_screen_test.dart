import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/get_cloze_task.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/cloze_test_screen.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_cloze_generator.dart';
import '../../domain/usecases/fakes/fake_cloze_task_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

const _task = ClozeTask(sentence: 'I ___ apples every day.', answer: 'eat');

/// Экран с фейками: словарь из одного слова, задание — из генератора.
///
/// `getClozeTaskProvider` собирается вручную, чтобы кэш и генератор были
/// управляемыми: экран не должен знать, откуда пришло задание.
Widget host({
  FakeClozeGenerator? generator,
  FakeClozeTaskRepository? tasks,
  List<Word> words = const [],
}) => ProviderScope(
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
        clock: () => now,
      ),
    ),
  ],
  child: const MaterialApp(home: ClozeTestScreen()),
);

void main() {
  testWidgets('renders sentence and input', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text(_task.sentence), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Проверить'), findsOneWidget);
  });

  testWidgets('typing correct answer shows success', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Eat');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    expect(find.text('Верно!'), findsOneWidget);
    // После верного ответа ввод закрыт, доступно следующее задание.
    expect(find.text('Следующее задание'), findsOneWidget);
  });

  testWidgets('wrong answer keeps the input open', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'drink');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    expect(find.text('Неверно'), findsOneWidget);
    expect(find.text('Проверить'), findsOneWidget);
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

    await tester.enterText(find.byType(TextField), 'eat');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Следующее задание'));
    await tester.pumpAndSettle();

    // Слово в словаре одно, поэтому второй показ берёт задание из кэша
    // и не ходит в сеть повторно.
    expect(generator.calls, 1);
    expect(find.text(_task.sentence), findsOneWidget);
  });

  testWidgets('marks the field red after a wrong answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'drink');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    final border = field.decoration!.enabledBorder! as OutlineInputBorder;
    expect(border.borderSide.style, BorderStyle.solid);
    expect(border.borderSide.width, 2);
  });

  testWidgets('clears the red border when the answer is edited', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'drink');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'eat');
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    final border = field.decoration!.enabledBorder! as OutlineInputBorder;
    expect(border.borderSide, BorderSide.none);
  });

  testWidgets('robot icon appears only after a wrong answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(ErrorHelperButton), findsNothing);

    await tester.enterText(find.byType(TextField), 'drink');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorHelperButton), findsOneWidget);
  });
}
