import 'package:english_edu/presentation/widgets/swipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host({required List<int> swipes, bool enabled = true}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        height: 400,
        child: SwipeCard(
          enabled: enabled,
          onSwiped: swipes.add,
          child: Container(
            color: Colors.teal,
            alignment: Alignment.center,
            child: const Text('card'),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('returns to rest when the drag is below the threshold', (
    tester,
  ) async {
    final swipes = <int>[];
    await tester.pumpWidget(host(swipes: swipes));

    await tester.drag(find.text('card'), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(swipes, isEmpty);
    expect(find.text('card'), findsOneWidget);
  });

  testWidgets('reports a right swipe after the card flies away', (
    tester,
  ) async {
    final swipes = <int>[];
    await tester.pumpWidget(host(swipes: swipes));

    await tester.drag(find.text('card'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(swipes, [1]);
  });

  testWidgets('reports a left swipe after the card flies away', (tester) async {
    final swipes = <int>[];
    await tester.pumpWidget(host(swipes: swipes));

    await tester.drag(find.text('card'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(swipes, [-1]);
  });

  testWidgets('ignores gestures when disabled', (tester) async {
    final swipes = <int>[];
    await tester.pumpWidget(host(swipes: swipes, enabled: false));

    await tester.drag(find.text('card'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(swipes, isEmpty);
  });

  testWidgets('shows the direction hint while dragging', (tester) async {
    await tester.pumpWidget(host(swipes: <int>[]));

    await tester.drag(find.text('card'), const Offset(120, 0));
    await tester.pump();

    expect(find.text('Знаю'), findsOneWidget);
  });
}
