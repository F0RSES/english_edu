import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/add_word_dialog.dart';
import 'package:english_edu/presentation/widgets/word_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_word_repository.dart';

Widget host(FakeWordRepository repo) => ProviderScope(
  overrides: [wordRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<bool>(
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

  testWidgets('warns about an existing term', (tester) async {
    final repo = FakeWordRepository([
      const Word(id: WordId(1), term: 'book', translation: 'книга'),
    ]);
    await tester.pumpWidget(host(repo));
    await openDialog(tester);

    await tester.enterText(find.byType(TextField).at(0), 'book');
    await tester.enterText(find.byType(TextField).at(1), 'книга');
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Слово уже есть'), findsOneWidget);
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
