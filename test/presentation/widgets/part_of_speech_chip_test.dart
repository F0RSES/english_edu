import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/presentation/widgets/part_of_speech_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

Widget host(String pos, {AppLanguage lang = AppLanguage.ru}) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWithValue(
      FakeSettingsRepository(UserSettings(language: lang)),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(body: PartOfSpeechChip(partOfSpeech: pos)),
  ),
);

void main() {
  testWidgets('tap opens explanation sheet in Russian', (tester) async {
    await tester.pumpWidget(host('noun'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pos-chip-noun')));
    await tester.pumpAndSettle();

    expect(find.text('noun / Существительное'), findsOneWidget);
    expect(find.textContaining('называет человека'), findsOneWidget);
    expect(find.textContaining('book, teacher, London'), findsOneWidget);
    expect(find.text('Понятно'), findsOneWidget);
    expect(find.byKey(const Key('app-bottom-sheet-handle')), findsOneWidget);
  });

  testWidgets('tap opens explanation sheet in English', (tester) async {
    await tester.pumpWidget(host('verb', lang: AppLanguage.en));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pos-chip-verb')));
    await tester.pumpAndSettle();

    expect(find.text('verb / Verb'), findsOneWidget);
    expect(find.textContaining('describes an action'), findsOneWidget);
    expect(find.textContaining('run, think, is'), findsOneWidget);
  });

  testWidgets('unknown part of speech renders plain chip without sheet', (
    tester,
  ) async {
    await tester.pumpWidget(host('phrase'));
    await tester.pumpAndSettle();

    expect(find.text('phrase'), findsOneWidget);
    expect(find.byKey(const Key('pos-chip-phrase')), findsNothing);

    await tester.tap(find.text('phrase'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
}
