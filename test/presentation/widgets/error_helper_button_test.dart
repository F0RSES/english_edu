import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/presentation/widgets/error_helper_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/fakes/fake_error_explainer.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';

Widget host(FakeErrorExplainer explainer) => ProviderScope(
  overrides: [
    errorExplainerProvider.overrideWithValue(explainer),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
  ],
  child: const MaterialApp(
    home: Scaffold(
      body: ErrorHelperButton(gameType: 'cloze_test', context: 'ошибка'),
    ),
  ),
);

void main() {
  testWidgets('renders icon', (tester) async {
    await tester.pumpWidget(host(FakeErrorExplainer()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    expect(find.byTooltip('Спросить у помощника'), findsOneWidget);
  });

  testWidgets('tap calls explain and shows bottom sheet', (tester) async {
    final explainer = FakeErrorExplainer(
      explanation: 'Глагол go в Past Simple — went.',
    );
    await tester.pumpWidget(host(explainer));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();

    expect(explainer.calls, 1);
    expect(explainer.lastGameType, 'cloze_test');
    expect(find.text('Помощник объясняет'), findsOneWidget);
    expect(find.text('Глагол go в Past Simple — went.'), findsOneWidget);

    await tester.tap(find.text('Понятно'));
    await tester.pumpAndSettle();

    expect(find.text('Помощник объясняет'), findsNothing);
  });

  testWidgets('error shows snackbar', (tester) async {
    final explainer = FakeErrorExplainer()..throwOnExplain = true;
    await tester.pumpWidget(host(explainer));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось получить объяснение'), findsOneWidget);
    expect(find.text('Помощник объясняет'), findsNothing);
  });
}
