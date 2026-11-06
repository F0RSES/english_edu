import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/user_category.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
import 'package:english_edu/presentation/widgets/word_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_word_repository.dart';

/// Базовые категории: в тестах БД нет, поэтому список подменяется явно.
List<UserCategory> seedCategories() => [
  for (var index = 0; index < wordCategories.length; index++)
    UserCategory(
      id: index + 1,
      name: wordCategories[index],
      colorHex: '#FF5722',
      createdAtUtc: DateTime.utc(2024, 5, 15, 12),
    ),
];

Widget host(FakeWordRepository repo) => ProviderScope(
  overrides: [
    wordRepositoryProvider.overrideWithValue(repo),
    userCategoriesProvider.overrideWith((ref) async => seedCategories()),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<AddWordOutcome>(
            context: context,
            builder: (_) => const AddWordDialog(),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('requires the term', (tester) async {
    await tester.pumpWidget(host(FakeWordRepository()));
    await openDialog(tester);

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Введите слово'), findsOneWidget);
  });

  testWidgets('requires the translation', (tester) async {
    await tester.pumpWidget(host(FakeWordRepository()));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'book');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Введите перевод'), findsOneWidget);
  });

  testWidgets('saves a new word with the next id', (tester) async {
    final repo = FakeWordRepository([
      const Word(id: WordId(5), term: 'one', translation: 'один'),
    ]);
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Book');
    await tester.enterText(find.byType(TextField).at(1), 'книга');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    final saved = await repo.getById(const WordId(6));
    expect(saved, isNotNull);
    expect(saved!.term, 'book');
    expect(saved.translation, 'книга');
  });

  testWidgets('shows the create category option', (tester) async {
    await tester.pumpWidget(host(FakeWordRepository()));
    await openDialog(tester);

    // Пункт «создать» есть в списке рядом с базовыми категориями (ADR-034).
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();

    expect(find.text('+ Создать категорию…'), findsOneWidget);
  });

  testWidgets('selecting category saves word with category', (tester) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'invoice');
    await tester.enterText(find.byType(TextField).at(1), 'счёт');
    // Поле категории — единственный дропдаун с nullable значением.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бизнес').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    final saved = (await repo.getAll()).single;
    expect(saved.term, 'invoice');
    expect(saved.category, 'Бизнес');
  });

  testWidgets('keeps category null when nothing is selected', (tester) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'book');
    await tester.enterText(find.byType(TextField).at(1), 'книга');
    // Пока категория не выбрана, поле показывает подпись пустого значения.
    expect(find.text(noCategoryLabel), findsOneWidget);
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect((await repo.getAll()).single.category, isNull);
  });

  testWidgets('saves word with selected level', (tester) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'ubiquitous');
    await tester.enterText(find.byType(TextField).at(1), 'вездесущий');
    // Уровень — единственный дропдаун с non-nullable CefrLevel.
    await tester.tap(find.byType(DropdownButtonFormField<CefrLevel>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('C1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect((await repo.getAll()).single.level, CefrLevel.c1);
  });

  testWidgets('defaults to A1', (tester) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'book');
    await tester.enterText(find.byType(TextField).at(1), 'книга');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect((await repo.getAll()).single.level, CefrLevel.a1);
  });

  testWidgets('shows all existing senses when homonyms exist', (tester) async {
    final repo = FakeWordRepository([
      const Word(
        id: WordId(1),
        term: 'apple',
        translation: 'яблоко',
        partOfSpeech: 'noun',
      ),
      const Word(
        id: WordId(2),
        term: 'apple',
        translation: 'компания',
        partOfSpeech: 'noun',
      ),
    ]);
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'apple');
    await tester.enterText(find.byType(TextField).at(1), 'яблоко');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('«apple» уже есть в словаре'), findsOneWidget);
    expect(find.text('Существующие значения:'), findsOneWidget);
    expect(find.text('• яблоко (noun)'), findsOneWidget);
    expect(find.text('• компания (noun)'), findsOneWidget);
    expect(find.text('Добавить ещё одно значение?'), findsOneWidget);
  });

  testWidgets('adds a second sense with a different id', (tester) async {
    final repo = FakeWordRepository([
      const Word(
        id: WordId(1),
        term: 'apple',
        translation: 'яблоко',
        partOfSpeech: 'noun',
      ),
    ]);
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Apple');
    await tester.enterText(find.byType(TextField).at(1), 'компания');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить как новое'));
    await tester.pumpAndSettle();

    final all = await repo.getAll();
    expect(all, hasLength(2));
    expect(all.map((word) => word.term), everyElement('apple'));
    expect(all.map((word) => word.id.value), containsAll([1, 2]));
    expect(find.byType(AddWordDialog), findsNothing);
  });

  testWidgets('cancel prevents adding a homonym', (tester) async {
    final repo = FakeWordRepository([
      const Word(id: WordId(1), term: 'apple', translation: 'яблоко'),
    ]);
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'apple');
    await tester.enterText(find.byType(TextField).at(1), 'компания');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    // Две кнопки «Отмена»: в форме и в диалоге гомонима. Последняя — диалог.
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();

    expect(await repo.count(), 1);
    expect(find.byType(AddWordDialog), findsOneWidget);
  });

  testWidgets('does not show the homonym dialog when the term is new', (
    tester,
  ) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'apple');
    await tester.enterText(find.byType(TextField).at(1), 'яблоко');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.textContaining('уже есть в словаре'), findsNothing);
    expect(await repo.count(), 1);
  });

  testWidgets('shows the homonym dialog for a single existing sense', (
    tester,
  ) async {
    final repo = FakeWordRepository([
      const Word(id: WordId(1), term: 'apple', translation: 'яблоко'),
    ]);
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'apple');
    await tester.enterText(find.byType(TextField).at(1), 'компания');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Добавить как новое'), findsOneWidget);
    expect(
      await repo.count(),
      1,
      reason: 'до подтверждения ничего не сохраняется',
    );
  });

  testWidgets('trims whitespace before saving', (tester) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), '  Book  ');
    await tester.enterText(find.byType(TextField).at(1), '  книга  ');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    final saved = (await repo.getAll()).single;
    expect(saved.term, 'book');
    expect(saved.translation, 'книга');
  });

  testWidgets('cancel closes without saving', (tester) async {
    final repo = FakeWordRepository();
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'book');
    await tester.enterText(find.byType(TextField).at(1), 'книга');
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(await repo.count(), 0);
    expect(find.byType(AddWordDialog), findsNothing);
  });
}
