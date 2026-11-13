import 'package:drift/native.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_progress_repository.dart';
import 'package:english_edu/data/repositories/drift_word_repository.dart';
import 'package:english_edu/domain/entities/word.dart' as domain;
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

/// Кладёт одно новое слово, чтобы очередь дня была непустой.
///
/// Кнопка старта выключена при пустой очереди, поэтому без сида навигацию
/// на урок проверить нельзя.
Future<void> seedOneNewWord(AppDatabase db) async {
  await DriftWordRepository(db).upsert(
    const domain.Word(id: WordId(1), term: 'hello', translation: 'привет'),
  );
  await DriftProgressRepository(db).upsert(
    WordProgress(
      wordId: const WordId(1),
      cardState: CardState.initial(now),
      status: WordStatus.newWord,
      firstSeenAt: now,
    ),
  );
}

void main() {
  testWidgets('navigates from home to the lesson screen', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await seedOneNewWord(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const EnglishEduApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Начать урок (1 слово)'), findsOneWidget);

    await tester.tap(find.text('Начать урок (1 слово)'));
    await tester.pumpAndSettle();

    // Очередь непустая, поэтому экран урока показывает карточку с оценками,
    // а не итог «На сегодня всё».
    expect(find.text('Знаю'), findsOneWidget);
  });
}
