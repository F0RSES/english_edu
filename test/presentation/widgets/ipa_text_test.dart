import 'package:english_edu/presentation/widgets/ipa_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(String transcription, {TextStyle? style}) => MaterialApp(
  home: Scaffold(body: IpaText(transcription, style: style)),
);

void main() {
  testWidgets('should_strip_framing_slashes_when_transcription_wrapped', (
    tester,
  ) async {
    await tester.pumpWidget(host('/daːrk/'));

    expect(find.text('daːrk'), findsOneWidget);
    expect(find.text('/daːrk/'), findsNothing);
  });

  testWidgets('should_keep_transcription_when_slashes_absent', (tester) async {
    await tester.pumpWidget(host('daːrk'));

    expect(find.text('daːrk'), findsOneWidget);
  });

  testWidgets('should_trim_edges_when_transcription_padded', (tester) async {
    await tester.pumpWidget(host(' /daːrk/ '));

    expect(find.text('daːrk'), findsOneWidget);
  });

  testWidgets('should_preserve_inner_marks_when_stripping_slashes', (
    tester,
  ) async {
    await tester.pumpWidget(host('/ˈæp.əl/'));

    expect(find.text('ˈæp.əl'), findsOneWidget);
  });

  testWidgets('should_render_empty_text_when_only_slashes_given', (
    tester,
  ) async {
    await tester.pumpWidget(host('//'));

    expect(find.text(''), findsOneWidget);
  });

  testWidgets('should_keep_lone_slash_when_no_closing_pair', (tester) async {
    await tester.pumpWidget(host('/'));

    expect(find.text('/'), findsOneWidget);
  });

  testWidgets('should_apply_given_style_when_rendering', (tester) async {
    const style = TextStyle(fontSize: 12, color: Colors.grey);
    await tester.pumpWidget(host('/daːrk/', style: style));

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style, style);
  });
}
