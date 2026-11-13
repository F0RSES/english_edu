import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/word_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/tts/fake_tts_service.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';

const word = Word(
  id: WordId(1),
  term: 'hello',
  translation: 'привет',
  transcription: '/həˈləʊ/',
  exampleSentence: 'Hello, world!',
);

Widget host({
  required bool revealed,
  FakeTtsService? tts,
  UserSettings? settings,
  VoidCallback? onTap,
}) =>
    ProviderScope(
      overrides: [
        ttsProvider.overrideWithValue(tts ?? FakeTtsService()),
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(settings),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: WordCard(
            word: word,
            revealed: revealed,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('renders term and transcription', (tester) async {
    await tester.pumpWidget(host(revealed: false));

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('/həˈləʊ/'), findsOneWidget);
  });

  testWidgets('hides the translation by default', (tester) async {
    await tester.pumpWidget(host(revealed: false));

    expect(find.text('привет'), findsNothing);
    expect(find.text('Нажмите, чтобы увидеть перевод'), findsOneWidget);
  });

  testWidgets('shows translation and example when revealed', (tester) async {
    await tester.pumpWidget(host(revealed: true));
    await tester.pumpAndSettle();

    expect(find.text('привет'), findsOneWidget);
    expect(find.text('Hello, world!'), findsOneWidget);
  });

  testWidgets('tap on the speaker speaks the term', (tester) async {
    final tts = FakeTtsService();
    await tester.pumpWidget(host(revealed: false, tts: tts));

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(tts.lastText, 'hello');
  });

  testWidgets('speaks with voice and speed from settings', (tester) async {
    final tts = FakeTtsService();
    final settings = UserSettings.defaults()
        .copyWith(ttsVoice: 'en-GB', ttsSpeed: 0.8);
    await tester.pumpWidget(
      host(revealed: false, tts: tts, settings: settings),
    );

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(tts.lastVoice, 'en-GB');
    expect(tts.lastSpeed, 0.8);
  });

  testWidgets('shows a snackbar when speech fails', (tester) async {
    final tts = FakeTtsService()..speakThrows = true;
    await tester.pumpWidget(host(revealed: false, tts: tts));

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(find.text('Озвучка недоступна'), findsOneWidget);
  });
}
