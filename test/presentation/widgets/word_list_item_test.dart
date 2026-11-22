import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/chat_screen.dart';
import 'package:english_edu/presentation/widgets/app_bottom_sheet.dart';
import 'package:english_edu/presentation/widgets/part_of_speech_chip.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_app_meta_repository.dart';
import '../../domain/usecases/fakes/fake_chat_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_word_repository.dart';

DictionaryEntry entry({
  WordStatus? status,
  String? partOfSpeech,
  String? transcription = '/həˈləʊ/',
  String? exampleSentence,
}) => DictionaryEntry(
  word: Word(
    id: const WordId(1),
    term: 'hello',
    translation: 'привет',
    transcription: transcription,
    partOfSpeech: partOfSpeech,
    exampleSentence: exampleSentence,
  ),
  status: status,
);

Widget host(
  DictionaryEntry item, {
  void Function(WordStatus)? onStatusChanged,
}) => ProviderScope(
  overrides: [
    // PartOfSpeechChip (Phase 51) читает язык через languageProvider.
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    // WordExampleSheet (Phase 55b) грузит статус изучения слова.
    wordRepositoryProvider.overrideWithValue(FakeWordRepository([item.word])),
    progressRepositoryProvider.overrideWithValue(FakeProgressRepository()),
    appMetaRepositoryProvider.overrideWithValue(FakeAppMetaRepository()),
    clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 21, 12)),
  ],
  child: MaterialApp(
    home: Scaffold(
      body: WordListItem(entry: item, onStatusChanged: onStatusChanged),
    ),
  ),
);

/// Роутер-харнесс для проверки навигации к ИИ-чату (Phase 39d).
Widget routerHost(DictionaryEntry item) {
  final router = GoRouter(
    initialLocation: '/dictionary',
    routes: [
      GoRoute(
        path: '/dictionary',
        builder: (context, state) => Scaffold(body: WordListItem(entry: item)),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra;
          return ChatScreen(initialContext: extra is String ? extra : null);
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
      aiClientProvider.overrideWithValue(
        AiClient(MockClient((_) async => http.Response('{}', 200))),
      ),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 13, 12)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders term, translation, IPA and part of speech chip', (
    tester,
  ) async {
    await tester.pumpWidget(host(entry(partOfSpeech: 'noun')));

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('привет'), findsOneWidget);
    // Phase 52a: на экране IPA без обрамляющих слэшей.
    expect(find.text('həˈləʊ'), findsOneWidget);
    // Phase 51: часть речи — чип с пояснением, не текст в meta-строке.
    expect(find.byType(PartOfSpeechChip), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
  });

  testWidgets('shows only the part of speech when IPA is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(entry(partOfSpeech: 'verb', transcription: null)),
    );

    expect(find.text('verb'), findsOneWidget);
  });

  testWidgets('shows only IPA when the part of speech is unknown', (
    tester,
  ) async {
    await tester.pumpWidget(host(entry()));

    expect(find.text('həˈləʊ'), findsOneWidget);
  });

  testWidgets('hides the meta line when IPA and part of speech are missing', (
    tester,
  ) async {
    await tester.pumpWidget(host(entry(transcription: null)));

    expect(find.text('привет'), findsOneWidget);
    expect(find.textContaining('•'), findsNothing);
  });

  testWidgets('does not render textual status badges', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.text('новое'), findsNothing);
    expect(find.text('изучаю'), findsNothing);
    expect(find.text('выучено'), findsNothing);
  });

  testWidgets('draws no status dot for a new word', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.byKey(const Key('word-status-dot')), findsNothing);
  });

  testWidgets('draws an amber dot for learning words', (tester) async {
    await tester.pumpWidget(host(entry(status: WordStatus.learning)));

    final dot = tester.widget<Container>(
      find.byKey(const Key('word-status-dot')),
    );
    expect(dot.decoration, isA<BoxDecoration>());
    expect((dot.decoration! as BoxDecoration).color, Colors.amber);
  });

  testWidgets('draws a green dot for mastered words', (tester) async {
    await tester.pumpWidget(host(entry(status: WordStatus.mastered)));

    final dot = tester.widget<Container>(
      find.byKey(const Key('word-status-dot')),
    );
    expect(dot.decoration, isA<BoxDecoration>());
    expect((dot.decoration! as BoxDecoration).color, Colors.green);
  });

  testWidgets('renders the AI avatar', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.byKey(const Key('word-ai-avatar')), findsOneWidget);
  });

  testWidgets('AI icon opens the chat with the word context', (tester) async {
    // Аватар в чате анимируется вечно: запрещаем анимации для pumpAndSettle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(routerHost(entry(partOfSpeech: 'interjection')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('word-ai-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.text,
      "Расскажи подробнее про слово 'hello' (перевод: привет, "
      'часть речи: interjection). Какие у него формы, примеры использования '
      'и типичные ошибки?',
    );
  });

  testWidgets('hides the status action without a callback', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);
  });

  testWidgets('should_open_example_sheet_when_card_tapped', (tester) async {
    await tester.pumpWidget(host(entry(exampleSentence: 'Hello, world!')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();

    // Phase 53b: пример в AppBottomSheet, SnackBar больше нет.
    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.text('Hello, world!', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('should_show_translate_button_in_sheet_when_no_example_ru', (
    tester,
  ) async {
    await tester.pumpWidget(host(entry(exampleSentence: 'Hello, world!')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();

    expect(find.text('Перевести'), findsOneWidget);
  });

  testWidgets('should_show_no_example_in_sheet_when_word_has_none', (
    tester,
  ) async {
    await tester.pumpWidget(host(entry()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();

    expect(find.text('Пример отсутствует'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows bookmark action for a new word', (tester) async {
    await tester.pumpWidget(host(entry(), onStatusChanged: (_) {}));

    expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);
  });

  testWidgets('shows check action for a learning word', (tester) async {
    await tester.pumpWidget(
      host(entry(status: WordStatus.learning), onStatusChanged: (_) {}),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('shows delete action for a mastered word', (tester) async {
    await tester.pumpWidget(
      host(entry(status: WordStatus.mastered), onStatusChanged: (_) {}),
    );

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('status action requests learning for a new word', (tester) async {
    WordStatus? requested;
    await tester.pumpWidget(
      host(entry(), onStatusChanged: (target) => requested = target),
    );

    await tester.tap(find.byIcon(Icons.bookmark_add_outlined));

    expect(requested, WordStatus.learning);
  });

  testWidgets('status action requests mastered for a learning word', (
    tester,
  ) async {
    WordStatus? requested;
    await tester.pumpWidget(
      host(
        entry(status: WordStatus.learning),
        onStatusChanged: (target) => requested = target,
      ),
    );

    await tester.tap(find.byIcon(Icons.check_circle_outline));

    expect(requested, WordStatus.mastered);
  });

  testWidgets('status action requests reset for a mastered word', (
    tester,
  ) async {
    WordStatus? requested;
    await tester.pumpWidget(
      host(
        entry(status: WordStatus.mastered),
        onStatusChanged: (target) => requested = target,
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));

    expect(requested, WordStatus.newWord);
  });
}
