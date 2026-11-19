import 'package:english_edu/presentation/widgets/animated_ai_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host({bool isTalking = false, bool winkOnStart = false}) => MaterialApp(
  home: Scaffold(
    body: AnimatedAiFace(
      size: 100,
      isTalking: isTalking,
      winkOnStart: winkOnStart,
    ),
  ),
);

double eyelidHeight(WidgetTester tester, String key) =>
    tester.getSize(find.byKey(Key(key))).height;

void main() {
  testWidgets('mouth appears only while talking and animates', (tester) async {
    await tester.pumpWidget(host());
    expect(find.byKey(const Key('ai-face-mouth')), findsNothing);

    await tester.pumpWidget(host(isTalking: true));
    await tester.pump();
    expect(find.byKey(const Key('ai-face-mouth')), findsOneWidget);
    final first = tester.getSize(find.byKey(const Key('ai-face-mouth'))).height;

    await tester.pump(const Duration(milliseconds: 125));
    final second = tester
        .getSize(find.byKey(const Key('ai-face-mouth')))
        .height;
    expect(second, isNot(first));
  });

  testWidgets('blinks periodically closing both eyes', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(eyelidHeight(tester, 'ai-face-left-eyelid'), 0);
    expect(eyelidHeight(tester, 'ai-face-right-eyelid'), 0);

    // Таймер моргания на 3.5 с; через 150 мс веки закрыты полностью.
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 150));
    expect(eyelidHeight(tester, 'ai-face-left-eyelid'), greaterThan(5));
    expect(eyelidHeight(tester, 'ai-face-right-eyelid'), greaterThan(5));

    await tester.pump(const Duration(milliseconds: 200));
    expect(eyelidHeight(tester, 'ai-face-left-eyelid'), 0);
    expect(eyelidHeight(tester, 'ai-face-right-eyelid'), 0);
  });

  testWidgets('wink closes only the left eye once', (tester) async {
    await tester.pumpWidget(host(winkOnStart: true));
    await tester.pump(const Duration(milliseconds: 200));

    expect(eyelidHeight(tester, 'ai-face-left-eyelid'), greaterThan(5));
    expect(eyelidHeight(tester, 'ai-face-right-eyelid'), 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(eyelidHeight(tester, 'ai-face-left-eyelid'), 0);
  });

  testWidgets('respects disableAnimations and disposes cleanly', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(host(isTalking: true, winkOnStart: true));
    await tester.pump(const Duration(seconds: 5));

    // Ни моргания, ни подмигивания; рот статичен.
    expect(eyelidHeight(tester, 'ai-face-left-eyelid'), 0);
    expect(eyelidHeight(tester, 'ai-face-right-eyelid'), 0);
    final first = tester.getSize(find.byKey(const Key('ai-face-mouth'))).height;
    await tester.pump(const Duration(milliseconds: 125));
    expect(
      tester.getSize(find.byKey(const Key('ai-face-mouth'))).height,
      first,
    );

    // Размонтирование: активные тикеры/таймер уронили бы тест.
    await tester.pumpWidget(const SizedBox());
  });
}
