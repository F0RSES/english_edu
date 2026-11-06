import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DictionaryEntry entry({WordStatus? status}) => DictionaryEntry(
  word: const Word(
    id: WordId(1),
    term: 'hello',
    translation: 'привет',
    transcription: '/həˈləʊ/',
  ),
  status: status,
);

Widget host(DictionaryEntry item) => MaterialApp(
  home: Scaffold(body: WordListItem(entry: item)),
);

void main() {
  testWidgets('renders term, translation and transcription', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('привет'), findsOneWidget);
    expect(find.text('/həˈləʊ/'), findsOneWidget);
  });

  testWidgets('shows the part of speech next to the translation', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const DictionaryEntry(
          word: Word(
            id: WordId(1),
            term: 'apple',
            translation: 'яблоко',
            partOfSpeech: 'noun',
          ),
        ),
      ),
    );

    // Часть речи отличает гомонимы друг от друга (ADR-031).
    expect(find.text('яблоко (noun)'), findsOneWidget);
  });

  testWidgets('omits the part of speech when it is unknown', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.text('привет'), findsOneWidget);
    expect(find.textContaining('('), findsNothing);
  });

  testWidgets('marks a word without progress as new', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.text('новое'), findsOneWidget);
  });

  testWidgets('shows the learning status', (tester) async {
    await tester.pumpWidget(host(entry(status: WordStatus.learning)));

    expect(find.text('изучаю'), findsOneWidget);
  });

  testWidgets('shows the mastered status', (tester) async {
    await tester.pumpWidget(host(entry(status: WordStatus.mastered)));

    expect(find.text('выучено'), findsOneWidget);
  });
}
