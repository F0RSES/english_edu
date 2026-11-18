import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/dictionary_entry.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/presentation/screens/chat_screen.dart';
import 'package:english_edu/presentation/widgets/word_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../domain/usecases/fakes/fake_chat_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';

DictionaryEntry entry({
  WordStatus? status,
  String? partOfSpeech,
  String? transcription = '/həˈləʊ/',
}) => DictionaryEntry(
  word: Word(
    id: const WordId(1),
    term: 'hello',
    translation: 'привет',
    transcription: transcription,
    partOfSpeech: partOfSpeech,
  ),
  status: status,
);

Widget host(DictionaryEntry item) => MaterialApp(
  home: Scaffold(body: WordListItem(entry: item)),
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
  testWidgets('renders term, translation and IPA • part of speech', (
    tester,
  ) async {
    await tester.pumpWidget(host(entry(partOfSpeech: 'noun')));

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('привет'), findsOneWidget);
    expect(find.text('/həˈləʊ/ • noun'), findsOneWidget);
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

    expect(find.text('/həˈləʊ/'), findsOneWidget);
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

  testWidgets('renders the AI icon', (tester) async {
    await tester.pumpWidget(host(entry()));

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('AI icon opens the chat with the word context', (tester) async {
    await tester.pumpWidget(routerHost(entry(partOfSpeech: 'interjection')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_awesome));
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
}
