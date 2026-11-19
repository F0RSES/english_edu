import 'package:english_edu/presentation/widgets/assistant_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _scheme = ColorScheme.fromSeed(seedColor: Colors.green);

Widget host(String data) => MaterialApp(
  theme: ThemeData(colorScheme: _scheme),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AssistantMarkdown(data: data),
      ),
    ),
  ),
);

/// Рекурсивный поиск жирного span с [text] (без зависимости от
/// семантики visitChildren).
bool _spanHasBold(InlineSpan span, String text) {
  if (span is! TextSpan) {
    return false;
  }
  if (span.style?.fontWeight == FontWeight.bold &&
      (span.text?.contains(text) ?? false)) {
    return true;
  }
  final children = span.children;
  return children != null && children.any((child) => _spanHasBold(child, text));
}

bool _hasBoldSpan(WidgetTester tester, String text) => tester
    .widgetList<RichText>(find.byType(RichText))
    .any((rich) => _spanHasBold(rich.text, text));

void main() {
  testWidgets('should_render_bold_without_raw_asterisks', (tester) async {
    await tester.pumpWidget(host('**hello**'));
    await tester.pumpAndSettle();

    expect(find.text('**hello**'), findsNothing);
    expect(find.text('hello'), findsOneWidget);
    expect(_hasBoldSpan(tester, 'hello'), isTrue);
  });

  testWidgets('should_render_list_items_without_raw_markers', (tester) async {
    await tester.pumpWidget(host('- First\n- Second'));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('- First'), findsNothing);
  });

  testWidgets('should_style_code_block_with_theme', (tester) async {
    await tester.pumpWidget(host('```\napple — яблоко\n```'));
    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.color == _scheme.surfaceContainerHighest &&
            decoration.borderRadius == BorderRadius.circular(12);
      }),
      isTrue,
    );
    expect(find.textContaining('apple — яблоко'), findsOneWidget);
  });

  testWidgets('should_scroll_long_code_line_without_overflow', (tester) async {
    final longLine = 'x' * 300;
    await tester.pumpWidget(host('```\n$longLine\n```'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Пакет оборачивает код в горизонтальный скролл — перенос не нужен.
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('should_render_table_cells', (tester) async {
    await tester.pumpWidget(
      host('| Word | Translation |\n|---|---|\n| apple | яблоко |'),
    );
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('яблоко'), findsOneWidget);
    expect(find.text('| apple | яблоко |'), findsNothing);
  });
}
