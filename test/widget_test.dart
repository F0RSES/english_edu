import 'package:drift/native.dart';
import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/di/review_log_id_generator.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots inside ProviderScope with overrides', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          nextReviewLogIdProvider.overrideWithValue(
            NextReviewLogIdGenerator(1).next,
          ),
          onboardingSeenProvider.overrideWith(
            () => OnboardingSeen(seeded: true),
          ),
        ],
        child: const EnglishEduApp(),
      ),
    );

    await tester.pumpAndSettle();
    // Главный экран с пустой базой показывает «Все слова изучены», поэтому
    // признак загрузки — заголовок приложения, а не текст кнопки урока.
    expect(find.text('English Edu'), findsOneWidget);
  });
}
