import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../domain/usecases/fakes/fake_settings_repository.dart';

/// Мини-роутер: экран онбординга и «главная», куда он уходит после «Начать».
Widget host(FakeSettingsRepository settings) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows the first slide with its copy', (tester) async {
    await tester.pumpWidget(host(FakeSettingsRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Карточки со словами'), findsOneWidget);
    expect(find.text('Далее'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);
  });

  testWidgets('moves to the next slide on Далее', (tester) async {
    await tester.pumpWidget(host(FakeSettingsRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();

    expect(find.text('Серия и заморозки'), findsOneWidget);
  });

  testWidgets('shows Начать on the last slide', (tester) async {
    await tester.pumpWidget(host(FakeSettingsRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();

    expect(find.text('AI-подсказки'), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Далее'), findsNothing);
  });

  testWidgets('completing onboarding saves hasSeenOnboarding = true', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(const UserSettings());
    await tester.pumpWidget(host(settings));
    await tester.pumpAndSettle();

    // «Пропустить» — самый короткий путь к завершению.
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect((await settings.get()).hasSeenOnboarding, isTrue);
    expect(find.text('home'), findsOneWidget);
  });
}
