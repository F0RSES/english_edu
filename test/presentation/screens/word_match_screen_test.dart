import 'dart:math';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/usecases/generate_memory_game.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/screens/word_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_word_repository.dart';

Widget host({int wordCount = 2}) => ProviderScope(
  overrides: [
    generateMemoryGameProvider.overrideWithValue(
      GenerateMemoryGame(
        words: FakeWordRepository([
          for (var id = 1; id <= wordCount; id++)
            Word(id: WordId(id), term: 'term$id', translation: 'перевод$id'),
        ]),
        random: Random(3),
        pairsCount: wordCount,
      ),
    ),
  ],
  child: const MaterialApp(home: WordMatchScreen()),
);

void main() {
  testWidgets('renders hidden cards for every pair', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Две пары: четыре закрытые карточки.
    expect(find.text('?'), findsNWidgets(4));
    expect(find.text('Ходы: 0'), findsOneWidget);
  });

  testWidgets('shows an empty state without words', (tester) async {
    await tester.pumpWidget(host(wordCount: 0));
    await tester.pumpAndSettle();

    expect(find.text('Добавьте слова в словарь'), findsOneWidget);
  });

  testWidgets('tapping a hidden card flips it', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Карточка 0 — английская сторона первой пары.
    final tile = find.byKey(const ValueKey('memory-card-0'));
    expect(find.descendant(of: tile, matching: find.text('?')), findsOneWidget);

    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(of: tile, matching: find.text('term1')),
      findsOneWidget,
    );
  });

  testWidgets('non-matching pair resets after 800ms', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // 0 и 2 — карточки разных пар.
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(const ValueKey('memory-card-2')));
    await tester.pump(const Duration(milliseconds: 100));

    final second = find.byKey(const ValueKey('memory-card-2'));
    expect(find.descendant(of: second, matching: find.text('?')), findsNothing);

    // UI закрывает несовпавшие через 800 мс.
    await tester.pump(const Duration(milliseconds: 900));

    expect(
      find.descendant(of: second, matching: find.text('?')),
      findsOneWidget,
    );
  });

  testWidgets('winning shows the dialog', (tester) async {
    await tester.pumpWidget(host(wordCount: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(const ValueKey('memory-card-1')));
    await tester.pumpAndSettle();

    expect(find.text('Победа!'), findsOneWidget);
  });
}
