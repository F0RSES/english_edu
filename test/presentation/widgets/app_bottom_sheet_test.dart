import 'package:english_edu/presentation/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sheetKey = Key('app-bottom-sheet');
const _handleKey = Key('app-bottom-sheet-handle');

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

ColorScheme schemeOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(_sheetKey))).colorScheme;

void main() {
  testWidgets('should_render_handle_and_content_when_built', (tester) async {
    await tester.pumpWidget(host(const AppBottomSheet(child: Text('content'))));

    expect(find.byKey(_handleKey), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('should_render_handle_and_content_when_shown', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                AppBottomSheet.show<void>(context, const Text('sheet-content')),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(_handleKey), findsOneWidget);
    expect(find.text('sheet-content'), findsOneWidget);
  });

  testWidgets('should_use_surface_low_and_rounded_top_when_rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppBottomSheet(child: SizedBox.shrink())),
    );

    final box = tester.widget<DecoratedBox>(find.byKey(_sheetKey));
    expect(
      box.decoration,
      BoxDecoration(
        color: schemeOf(tester).surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  });

  testWidgets('should_draw_handle_with_spec_geometry_when_rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppBottomSheet(child: SizedBox.shrink())),
    );

    final handle = tester.widget<Container>(find.byKey(_handleKey));
    expect(
      handle.constraints,
      const BoxConstraints.tightFor(width: 40, height: 4),
    );
    expect(handle.margin, const EdgeInsets.only(top: 12, bottom: 8));
    expect(
      handle.decoration,
      BoxDecoration(
        color: schemeOf(tester).outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  });

  testWidgets('should_protect_content_with_safe_area_when_rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AppBottomSheet(child: SizedBox.shrink())),
    );

    expect(
      find.descendant(
        of: find.byKey(_sheetKey),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );
  });

  testWidgets('should_return_result_when_sheet_popped_with_value', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await AppBottomSheet.show<String>(
                context,
                Builder(
                  builder: (sheetContext) => ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, 'done'),
                    child: const Text('close'),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(result, 'done');
  });
}
