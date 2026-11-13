import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/presentation/widgets/daily_goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const today = LocalDate(20000);

DailyStats stats({required int newWords, required int reviews}) => DailyStats(
  date: today,
  newWordsStudied: newWords,
  reviewsCompleted: reviews,
  xpGained: 0,
  correctAnswers: 0,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders done and target counts', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DailyGoalCard(stats: stats(newWords: 3, reviews: 2), totalTarget: 10),
      ),
    );

    expect(find.text('5 / 10 слов сегодня'), findsOneWidget);
  });

  testWidgets('renders zero when there are no stats for the day', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const DailyGoalCard(stats: null, totalTarget: 10)),
    );

    expect(find.text('0 / 10 слов сегодня'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.0,
    );
  });

  testWidgets('clamps progress to full when the target is exceeded', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DailyGoalCard(stats: stats(newWords: 8, reviews: 7), totalTarget: 10),
      ),
    );

    expect(find.text('15 / 10 слов сегодня'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1.0,
    );
  });
}
