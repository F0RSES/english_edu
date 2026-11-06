import 'dart:async';
import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_scramble_puzzles.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/word_scramble_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_word_repository.dart';

Word word(int id, String term, String translation) =>
    Word(id: WordId(id), term: term, translation: translation);

/// Словарь из двух слов: «apple» и «book».
List<Word> twoWords() => [word(1, 'apple', 'яблоко'), word(2, 'book', 'книга')];

/// Экран поверх настоящего use case.
///
/// Генератор не подменяется: он `final`, и это правильно — иначе тест проверял
/// бы собственную заглушку. Управляем словарём, а seed фиксирует перемешивание.
Widget host({List<Word>? words, FakeWordRepository? repo}) {
  final wordRepo = repo ?? FakeWordRepository(words ?? twoWords());
  return ProviderScope(
    overrides: [
      wordRepositoryProvider.overrideWithValue(wordRepo),
      generateScramblePuzzlesProvider.overrideWithValue(
        GenerateScramblePuzzles(words: wordRepo, random: Random(5)),
      ),
    ],
    child: const MaterialApp(home: WordScrambleScreen()),
  );
}

/// Тапает буквы в порядке [letters], различая повторы по порядку кнопок.
Future<void> tapLetters(WidgetTester tester, String letters) async {
  final seen = <String, int>{};
  for (final letter in letters.split('')) {
    final index = seen.update(letter, (value) => value + 1, ifAbsent: () => 0);
    await tester.tap(find.widgetWithText(FilledButton, letter).at(index));
    await tester.pump();
  }
}

/// Решает текущую карточку, определяя слово по переводу.
///
/// Порядок слов в сессии случайный, поэтому тест не предполагает, какое слово
/// показано первым.
Future<void> solveCurrent(WidgetTester tester) async {
  final isApple = find.text('яблоко').evaluate().isNotEmpty;
  await tapLetters(tester, isApple ? 'apple' : 'book');
}

void main() {
  testWidgets('renders loading state', (tester) async {
    final pending = Completer<void>();
    final repo = FakeWordRepository(twoWords())
      ..beforeGetAll = () => pending.future;

    await tester.pumpWidget(host(repo: repo));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Готовим задание...'), findsOneWidget);

    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('renders translation and letter buttons', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Первым может быть любое из двух слов — проверяем общие признаки.
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('0 верно'), findsOneWidget);
    expect(find.text('Очистить'), findsOneWidget);
    final translation = find.text('яблоко').evaluate().isNotEmpty
        ? 'яблоко'
        : 'книга';
    expect(find.text(translation), findsOneWidget);
  });

  testWidgets('tapping letters builds answer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Одна буква: автопроверка не запускается, плашка ответа непуста.
    final solution = find.text('яблоко').evaluate().isNotEmpty
        ? 'apple'
        : 'book';
    await tapLetters(tester, solution.substring(0, 1));

    expect(find.text(solution.substring(0, 1)), findsWidgets);
    expect(find.text('Неверно'), findsNothing);
  });

  testWidgets('correct answer shows success and advances', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await solveCurrent(tester);
    await tester.pump();

    expect(find.text('Правильно!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('wrong answer clears after shake', (tester) async {
    // Одно слово: ответ известен, а перестановка «elppa» заведомо неверна.
    await tester.pumpWidget(host(words: [word(1, 'apple', 'яблоко')]));
    await tester.pumpAndSettle();

    await tapLetters(tester, 'elppa');
    await tester.pump();

    expect(find.text('Неверно'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Ответ сброшен, карточка та же, счётчик не вырос.
    expect(find.text('яблоко'), findsOneWidget);
    expect(find.text('0 верно'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('clear button resets', (tester) async {
    await tester.pumpWidget(host(words: [word(1, 'apple', 'яблоко')]));
    await tester.pumpAndSettle();

    await tapLetters(tester, 'a');
    await tester.tap(find.text('Очистить'));
    await tester.pump();

    // Плашка ответа пуста: единственная «a» на экране — кнопка буквы.
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('session complete shows dialog', (tester) async {
    await tester.pumpWidget(host(words: [word(1, 'apple', 'яблоко')]));
    await tester.pumpAndSettle();

    await tapLetters(tester, 'apple');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.text('Верно: 1 из 1'), findsOneWidget);
  });

  testWidgets('shows error state when the dictionary fails', (tester) async {
    final repo = FakeWordRepository(twoWords())
      ..beforeGetAll = () async => throw StateError('boom');

    await tester.pumpWidget(host(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
