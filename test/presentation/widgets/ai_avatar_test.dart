import 'package:english_edu/presentation/widgets/ai_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host({bool isTalking = false}) => MaterialApp(
  home: Scaffold(body: AiAvatar(isTalking: isTalking)),
);

/// Парение — Transform.translate по ключу; дыхание — Transform.scale.
///
/// Scale читается из storage[0] (X): getMaxScaleOnAxis учитывает ось Z=1
/// и для scale<1 всегда вернул бы 1.0.
double floatOf(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const Key('ai-avatar-float')))
    .transform
    .getTranslation()
    .y;

double scaleOf(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const Key('ai-avatar-breath')))
    .transform
    .storage[0];

void main() {
  testWidgets('renders the mascot image', (tester) async {
    await tester.pumpWidget(host());

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/ai_avatar.png',
    );
  });

  testWidgets('idle animation floats and breathes within idle bounds', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 500));

    final firstFloat = floatOf(tester);
    final firstScale = scaleOf(tester);
    expect(firstFloat.abs(), lessThanOrEqualTo(4.0));
    expect(firstScale, inInclusiveRange(0.98, 1.02));

    await tester.pump(const Duration(milliseconds: 500));
    expect(floatOf(tester), isNot(firstFloat));
  });

  testWidgets('talking mode bounces wider and faster than idle', (
    tester,
  ) async {
    await tester.pumpWidget(host(isTalking: true));
    await tester.pump(const Duration(milliseconds: 100));

    // На 100 мс talking-цикла scale < 0.98 — idle так низко не опускается.
    expect(scaleOf(tester), lessThan(0.98));
    expect(scaleOf(tester), greaterThanOrEqualTo(0.95));
    expect(floatOf(tester).abs(), lessThanOrEqualTo(2.0));
  });

  testWidgets('switches modes and disposes the controller', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(host(isTalking: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scaleOf(tester), lessThan(0.98));

    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));
    expect(scaleOf(tester), greaterThanOrEqualTo(0.98));

    // Размонтирование: активный тикер после dispose уронил бы тест.
    await tester.pumpWidget(const SizedBox());
  });
}
