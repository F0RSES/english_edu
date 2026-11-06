import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/analytics.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/presentation/widgets/analytics_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final today = LocalDate.fromDateTime(DateTime.utc(2024, 5, 15, 12));

DailyStats day(int offset, {int answers = 1}) => DailyStats(
  date: today.addDays(-offset),
  newWordsStudied: answers,
  reviewsCompleted: 0,
  xpGained: 0,
  correctAnswers: answers,
);

Analytics analyticsOf({
  int mastered = 1,
  int learning = 1,
  int fresh = 4,
  List<HardWord>? hardWords,
  List<DailyStats>? days,
  LocalDate? projected,
}) => Analytics(
  totalWords: mastered + learning + fresh,
  masteredCount: mastered,
  learningCount: learning,
  newCount: fresh,
  hardestWords: hardWords ?? const [],
  last7Days: days ?? [for (var offset = 6; offset >= 0; offset--) day(offset)],
  projectedMasteryDate: projected,
);

Widget host(Analytics analytics) => ProviderScope(
  overrides: [analyticsProvider.overrideWith((ref) => analytics)],
  child: const MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: AnalyticsSection())),
  ),
);

HardWord hardWord(int id, int lapses) => HardWord(
  word: Word(id: WordId(id), term: 'term$id', translation: 'перевод$id'),
  lapses: lapses,
);

void main() {
  testWidgets('renders status tiles with counts', (tester) async {
    await tester.pumpWidget(host(analyticsOf()));
    await tester.pumpAndSettle();

    expect(find.text('Всего'), findsOneWidget);
    expect(find.text('Выучено'), findsOneWidget);
    expect(find.text('Изучаю'), findsOneWidget);
    expect(find.text('Новые'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('renders one bar per day', (tester) async {
    await tester.pumpWidget(host(analyticsOf()));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('bar-'),
      ),
      findsNWidgets(7),
    );
  });

  testWidgets('renders hard words with their lapse count', (tester) async {
    await tester.pumpWidget(
      host(analyticsOf(hardWords: [hardWord(1, 3), hardWord(2, 1)])),
    );
    await tester.pumpAndSettle();

    expect(find.text('term1'), findsOneWidget);
    expect(find.text('3 провала'), findsOneWidget);
    expect(find.text('1 провал'), findsOneWidget);
  });

  testWidgets('shows a placeholder when there are no hard words', (
    tester,
  ) async {
    await tester.pumpWidget(host(analyticsOf()));
    await tester.pumpAndSettle();

    expect(find.text('Пока нет провалов'), findsOneWidget);
  });

  testWidgets('renders the mastery projection date', (tester) async {
    await tester.pumpWidget(
      host(
        analyticsOf(projected: LocalDate.fromDateTime(DateTime.utc(2026, 2))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Все слова mastered к 01.02.2026'), findsOneWidget);
  });

  testWidgets('renders a dash when the projection is unknown', (tester) async {
    await tester.pumpWidget(host(analyticsOf()));
    await tester.pumpAndSettle();

    expect(find.text('Прогноз mastery: —'), findsOneWidget);
  });
}
