import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/services/word_translator.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:english_edu/presentation/widgets/bulk_dictionary_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_translation_generator.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

const _words = ['eat', 'eats', 'ate', 'eating', 'eaten'];

Widget host({FakeWordRepository? words, TranslationGenerator? generator}) =>
    ProviderScope(
      overrides: [
        wordRepositoryProvider.overrideWithValue(words ?? FakeWordRepository()),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        translationGeneratorProvider.overrideWithValue(
          generator ?? FakeTranslationGenerator(),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: BulkDictionarySheet(words: _words)),
      ),
    );

/// Переводчик, который ждёт Completer: проверка лоадеров.
final class _PendingGenerator implements TranslationGenerator {
  final completer = Completer<WordTranslation>();

  @override
  Future<WordTranslation> translate(String word) => completer.future;
}

void main() {
  testWidgets('renders five words with translations', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Слова в задании'), findsOneWidget);
    for (final word in _words) {
      expect(find.text(word), findsOneWidget);
    }
    expect(find.text('учреждение'), findsNWidgets(5));
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(5));
  });

  testWidgets('add inserts word and toggles to delete', (tester) async {
    final words = FakeWordRepository();
    await tester.pumpWidget(host(words: words));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    final added = await words.findByTerm('eat');
    expect(added, isNotNull);
    expect(added!.translation, 'учреждение');
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(4));
  });

  testWidgets('delete removes word and toggles back to add', (tester) async {
    final words = FakeWordRepository([
      const Word(id: WordId(1), term: 'eat', translation: 'есть'),
    ]);
    await tester.pumpWidget(host(words: words));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(await words.findByTerm('eat'), isNull);
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(5));
  });

  testWidgets('shows loaders while translations are pending', (tester) async {
    final generator = _PendingGenerator();
    await tester.pumpWidget(host(generator: generator));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNWidgets(5));
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

    generator.completer.complete(const WordTranslation(text: 'перевод'));
    await tester.pumpAndSettle();

    expect(find.text('перевод'), findsNWidgets(5));
  });
}
