import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:english_edu/presentation/screens/achievements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final moment = DateTime.utc(2024, 5, 15, 12);

Achievement item(AchievementType type, {int progress = 0, bool open = false}) =>
    Achievement(
      type: type,
      progress: progress,
      unlockedAt: open ? moment : null,
      lastUpdatedAt: moment,
    );

Widget host(List<Achievement> items) => ProviderScope(
  overrides: [achievementsProvider.overrideWith((ref) async => items)],
  child: const MaterialApp(home: AchievementsScreen()),
);

void main() {
  testWidgets('renders grid of achievements', (tester) async {
    await tester.pumpWidget(
      host([
        item(AchievementType.words100, progress: 40),
        item(AchievementType.streak7, progress: 7, open: true),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('100 слов'), findsOneWidget);
    expect(find.text('7 дней подряд'), findsOneWidget);
    expect(find.text('40/100'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
  });

  testWidgets('splits unlocked and in-progress sections', (tester) async {
    await tester.pumpWidget(
      host([
        item(AchievementType.streak7, progress: 7, open: true),
        item(AchievementType.words500, progress: 10),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Разблокировано (1)'), findsOneWidget);
    expect(find.text('В процессе (1)'), findsOneWidget);
  });
}
