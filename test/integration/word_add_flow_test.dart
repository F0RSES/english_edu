import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';
import 'package:english_edu/presentation/screens/dictionary_screen.dart';
import 'package:english_edu/presentation/widgets/ai_word_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/usecases/fakes/fake_translation_generator.dart';

/// Интеграционный тест потока добавления слова (Phase 50).
///
/// Реальная in-memory БД, реальные Drift-репозитории, реальный
/// UpdateWordStatus и dictionaryEntriesProvider; фейк — только переводчик.
/// Проверяет, что слово попадает во вкладку «Изучаю» словаря.
const _translation = WordTranslation(
  text: 'учреждение',
  partOfSpeech: 'noun',
  transcription: '/fəˈsɪləti/',
  example: 'The facility is new.',
);

final _now = DateTime.utc(2026, 11, 20, 12);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget scope(Widget child) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      translationGeneratorProvider.overrideWithValue(
        FakeTranslationGenerator(translation: _translation),
      ),
      clockProvider.overrideWithValue(() => _now),
    ],
    child: MaterialApp(home: child),
  );

  Future<void> confirmViaSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-add-word')));
    await tester.pumpAndSettle();
  }

  Future<void> openLearningTab(WidgetTester tester) async {
    // Лист перевода остаётся открытым после добавления (UX Phase 49) —
    // закрываем его, иначе он перекрывает словарь.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(scope(const DictionaryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Изучаю'));
    await tester.pumpAndSettle();
  }

  testWidgets('new word added via plus appears in Learning tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      scope(const Scaffold(body: AiWordHelper(word: 'facility'))),
    );
    await tester.pumpAndSettle();

    // Активные фильтры словаря скрыли бы новое слово (баг 3 Phase 50):
    // поток обязан сбросить их после добавления.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AiWordHelper)),
    );
    container.read(dictionarySearchQueryProvider.notifier).update('zzz');
    container.read(dictionaryLevelFilterProvider.notifier).update(CefrLevel.c2);

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    await confirmViaSheet(tester);

    // БД: слово создано, прогресс сразу learning.
    final words = await db.select(db.words).get();
    expect(words.map((w) => w.term), contains('facility'));
    final progress = await db.select(db.wordProgresses).get();
    expect(progress.single.status, 'learning');

    await openLearningTab(tester);
    expect(find.text('facility'), findsOneWidget);
  });

  testWidgets('existing seed word gets learning status without duplicate', (
    tester,
  ) async {
    // Seed-слово уже в словаре со статусом mastered (сценарий бага 2).
    await db
        .into(db.words)
        .insert(
          WordsCompanion.insert(
            id: const Value(1),
            term: 'facility',
            translation: 'учреждение',
          ),
        );
    await db
        .into(db.wordProgresses)
        .insert(
          WordProgressesCompanion.insert(
            wordId: const Value(1),
            easePermille: 2500,
            intervalDays: 30,
            repetitions: 6,
            lapses: 0,
            dueAtUtc: _now.millisecondsSinceEpoch,
            status: 'mastered',
            firstSeenAtUtc: _now.millisecondsSinceEpoch,
          ),
        );

    await tester.pumpWidget(
      scope(const Scaffold(body: AiWordHelper(word: 'facility'))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('facility'));
    await tester.pumpAndSettle();
    // Существующему слову доступны оба действия: «+» и корзина.
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await confirmViaSheet(tester);

    // Дубликата нет, seed-перевод сохранён, статус переведён в learning.
    final words = await db.select(db.words).get();
    expect(words, hasLength(1));
    expect(words.single.translation, 'учреждение');
    final progress = await db.select(db.wordProgresses).get();
    expect(progress.single.status, 'learning');

    await openLearningTab(tester);
    expect(find.text('facility'), findsOneWidget);
  });
}
