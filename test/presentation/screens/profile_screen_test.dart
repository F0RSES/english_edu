import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/tts/fake_tts_service.dart';
import '../../domain/usecases/fakes/fake_frozen_days_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_review_log_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';

final class Harness {
  Harness({UserSettings? settings, List<DailyStats> stats = const []})
    : settingsRepo = FakeSettingsRepository(settings),
      statsRepo = FakeStatsRepository(stats),
      tts = FakeTtsService();

  final FakeSettingsRepository settingsRepo;
  final FakeStatsRepository statsRepo;
  final FakeProgressRepository progressRepo = FakeProgressRepository();
  final FakeReviewLogRepository logRepo = FakeReviewLogRepository();
  final FakeTtsService tts;

  Widget app() => ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      statsRepositoryProvider.overrideWithValue(statsRepo),
      frozenDaysRepositoryProvider.overrideWithValue(
        FakeFrozenDaysRepository(),
      ),
      progressRepositoryProvider.overrideWithValue(progressRepo),
      reviewLogRepositoryProvider.overrideWithValue(logRepo),
      ttsProvider.overrideWithValue(tts),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

final class _ThrowingSettings implements SettingsRepository {
  @override
  Future<UserSettings> get() async => throw StateError('boom');

  @override
  Future<void> save(UserSettings settings) async {}
}

void main() {
  testWidgets('changing the voice saves settings', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('en-US'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('en-GB').last);
    await tester.pumpAndSettle();

    expect((await harness.settingsRepo.get()).ttsVoice, 'en-GB');
  });

  testWidgets('moving the speed slider saves settings', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    // Слайдеров три: два лимита и скорость — адресуем по подписи плитки.
    final speedSlider = find.descendant(
      of: find.widgetWithText(ListTile, 'Скорость речи'),
      matching: find.byType(Slider),
    );
    await tester.drag(speedSlider, const Offset(80, 0));
    await tester.pumpAndSettle();

    final saved = (await harness.settingsRepo.get()).ttsSpeed;
    expect(saved, isNot(UserSettings.defaults().ttsSpeed));
    expect(saved, greaterThan(0.5));
  });

  testWidgets('test button speaks with the current settings', (tester) async {
    final harness = Harness(
      settings: UserSettings.defaults().copyWith(
        ttsVoice: 'en-GB',
        ttsSpeed: 0.7,
      ),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    expect(harness.tts.lastText, 'Hello world');
    expect(harness.tts.lastVoice, 'en-GB');
    expect(harness.tts.lastSpeed, 0.7);
  });

  testWidgets('reminders toggle is disabled with a Phase 5 hint', (
    tester,
  ) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    // Секция напоминаний — внизу длинного списка.
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 200);
    await tester.pumpAndSettle();

    expect(find.text('Появится в Phase 5 (BL-38)'), findsOneWidget);
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNull);
  });

  testWidgets('shows an error state when settings fail to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(_ThrowingSettings()),
          ttsProvider.overrideWithValue(FakeTtsService()),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить настройки'), findsOneWidget);
  });

  testWidgets('daily new limit slider saves settings', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    final slider = find.descendant(
      of: find.widgetWithText(ListTile, 'Новых слов в день'),
      matching: find.byType(Slider),
    );
    await tester.drag(slider, const Offset(80, 0));
    await tester.pumpAndSettle();

    final saved = (await harness.settingsRepo.get()).dailyNewLimit;
    // Драг идёт от центра виджета, поэтому проверяем изменение и шаг 5,
    // а не конкретное направление.
    expect(saved, isNot(UserSettings.defaults().dailyNewLimit));
    expect(saved % 5, 0);
  });

  testWidgets('daily review limit slider saves settings', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    final slider = find.descendant(
      of: find.widgetWithText(ListTile, 'Повторений в день'),
      matching: find.byType(Slider),
    );
    await tester.drag(slider, const Offset(-80, 0));
    await tester.pumpAndSettle();

    final saved = (await harness.settingsRepo.get()).dailyReviewLimit;
    expect(saved, isNot(UserSettings.defaults().dailyReviewLimit));
    expect(saved % 10, 0);
  });

  testWidgets('reset button asks for confirmation', (tester) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Сбросить прогресс'), 200);
    await tester.tap(find.text('Сбросить прогресс'));
    await tester.pumpAndSettle();

    expect(find.text('Сбросить прогресс?'), findsOneWidget);
    // До подтверждения данные не тронуты.
    expect(await harness.statsRepo.getAll(), isEmpty);
  });

  testWidgets('confirm reset clears progress and refreshes derived data', (
    tester,
  ) async {
    final harness = Harness(
      stats: [
        DailyStats(
          date: LocalDate.fromDateTime(DateTime.now()),
          newWordsStudied: 1,
          reviewsCompleted: 0,
          xpGained: 10,
          correctAnswers: 1,
        ),
      ],
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfileScreen)),
    );
    // Серия посчитана и лежит в кэше — после сброса она должна стать нулевой.
    expect((await container.read(computeStreakProvider.future)).count, 1);

    await tester.scrollUntilVisible(find.text('Сбросить прогресс'), 200);
    await tester.tap(find.text('Сбросить прогресс'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();

    expect(await harness.statsRepo.getAll(), isEmpty);
    expect(await harness.progressRepo.getAll(), isEmpty);
    expect(await harness.logRepo.getAll(), isEmpty);
    expect((await container.read(computeStreakProvider.future)).count, 0);
  });
}
