import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/presentation/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Дата экрана для проверки «свежести» заморозки.
const today = LocalDate(20007);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows a prompt instead of a zero streak', (tester) async {
    await tester.pumpWidget(
      _wrap(const StreakCard(streak: StreakInfo(count: 0), today: today)),
    );

    expect(find.text('Начни серию сегодня'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('shows the count as a separate large number', (tester) async {
    await tester.pumpWidget(
      _wrap(const StreakCard(streak: StreakInfo(count: 5), today: today)),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('дней подряд'), findsOneWidget);
  });

  testWidgets('does not show last activity date (Phase 26c)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StreakCard(
          streak: StreakInfo(count: 5, lastActiveLocalDate: LocalDate(20000)),
          today: today,
        ),
      ),
    );

    expect(find.textContaining('Последняя активность'), findsNothing);
  });

  testWidgets('declines the word "day" for every count form', (tester) async {
    const forms = <int, String>{
      1: 'день',
      2: 'дня',
      5: 'дней',
      11: 'дней',
      21: 'день',
      22: 'дня',
      111: 'дней',
    };

    for (final form in forms.entries) {
      await tester.pumpWidget(
        _wrap(
          StreakCard(
            streak: StreakInfo(count: form.key),
            today: today,
          ),
        ),
      );

      expect(
        find.text('${form.value} подряд'),
        findsOneWidget,
        reason: 'count=${form.key} должен давать «${form.value}»',
      );
    }
  });

  testWidgets('counts down to the first milestone', (tester) async {
    await tester.pumpWidget(
      _wrap(const StreakCard(streak: StreakInfo(count: 5), today: today)),
    );

    expect(find.text('До 7 дней: 2 дня'), findsOneWidget);
  });

  testWidgets('celebrates seven days', (tester) async {
    await tester.pumpWidget(
      _wrap(const StreakCard(streak: StreakInfo(count: 7), today: today)),
    );

    expect(find.text('🎉 7 дней! Молодец'), findsOneWidget);
  });

  testWidgets('celebrates thirty days', (tester) async {
    await tester.pumpWidget(
      _wrap(const StreakCard(streak: StreakInfo(count: 30), today: today)),
    );

    expect(find.text('🔥 30 дней! Огонь'), findsOneWidget);
  });

  testWidgets('shows frozenAvailable badge only when recently used', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const StreakCard(
          streak: StreakInfo(count: 7, frozenAvailable: 2),
          today: today,
        ),
      ),
    );

    // Текст «🧊 N заморозок доступно» убран из карточки (Phase 26c).
    expect(find.textContaining('заморозк'), findsNothing);
  });

  testWidgets('shows the badge for a freeze used in the last week', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StreakCard(
          streak: StreakInfo(count: 3, frozenDates: {today.addDays(-1)}),
          today: today,
        ),
      ),
    );

    expect(find.text('Freeze использован'), findsOneWidget);
  });

  testWidgets('hides the badge when the freeze is older than a week', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StreakCard(
          streak: StreakInfo(count: 3, frozenDates: {today.addDays(-10)}),
          today: today,
        ),
      ),
    );

    expect(find.text('Freeze использован'), findsNothing);
  });
}
