import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/services/cloud_auth_service.dart';
import 'package:english_edu/domain/services/cloud_sync_service.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/notifications/fake_notification_service.dart';
import '../../core/sync/fake_cloud_auth_service.dart';
import '../../core/sync/fake_cloud_sync_service.dart';
import '../../core/tts/fake_tts_service.dart';
import '../../domain/usecases/fakes/fake_frozen_days_repository.dart';
import '../../domain/usecases/fakes/fake_progress_repository.dart';
import '../../domain/usecases/fakes/fake_review_log_repository.dart';
import '../../domain/usecases/fakes/fake_settings_repository.dart';
import '../../domain/usecases/fakes/fake_stats_repository.dart';

/// Секция напоминаний — внизу длинного списка.
Future<void> _scrollToReminders(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.byType(SwitchListTile), 200);
  await tester.pumpAndSettle();
}

final class Harness {
  Harness({
    UserSettings? settings,
    List<DailyStats> stats = const [],
    CloudAuthService? auth,
    CloudSyncService? sync,
  }) : settingsRepo = FakeSettingsRepository(settings),
       statsRepo = FakeStatsRepository(stats),
       auth = auth ?? FakeCloudAuthService(available: false),
       sync = sync ?? FakeCloudSyncService(),
       tts = FakeTtsService();

  final FakeNotificationService notifications = FakeNotificationService();

  final FakeSettingsRepository settingsRepo;
  final FakeStatsRepository statsRepo;
  final FakeProgressRepository progressRepo = FakeProgressRepository();
  final FakeReviewLogRepository logRepo = FakeReviewLogRepository();
  final CloudAuthService auth;
  final CloudSyncService sync;
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
      notificationServiceProvider.overrideWithValue(notifications),
      cloudAuthServiceProvider.overrideWithValue(auth),
      cloudSyncServiceProvider.overrideWithValue(sync),
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

  testWidgets('reminders toggle reflects the saved setting', (tester) async {
    final harness = Harness(
      settings: const UserSettings(remindersEnabled: true),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _scrollToReminders(tester);

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
    expect(tile.onChanged, isNotNull);
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

  testWidgets('enabling reminders asks permission and schedules', (
    tester,
  ) async {
    final harness = Harness(
      settings: const UserSettings(reminderHour: 7, reminderMinute: 15),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _scrollToReminders(tester);

    await tester.tap(find.text('Включить напоминания'));
    await tester.pumpAndSettle();

    expect(harness.notifications.requestPermissionCalls, 1);
    expect(harness.notifications.scheduleCalls.single, (hour: 7, minute: 15));
    expect((await harness.settingsRepo.get()).remindersEnabled, isTrue);
  });

  testWidgets('disabling reminders cancels them', (tester) async {
    final harness = Harness(
      settings: const UserSettings(remindersEnabled: true),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _scrollToReminders(tester);

    await tester.tap(find.text('Включить напоминания'));
    await tester.pumpAndSettle();

    expect(harness.notifications.cancelCalls, 1);
    expect(harness.notifications.scheduleCalls, isEmpty);
    expect((await harness.settingsRepo.get()).remindersEnabled, isFalse);
  });

  testWidgets('time picker saves the new time and reschedules', (tester) async {
    final harness = Harness(
      settings: const UserSettings(remindersEnabled: true),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _scrollToReminders(tester);

    await tester.tap(find.text('Время напоминания'));
    await tester.pumpAndSettle();

    // Ввод с клавиатуры: часы и минуты — два поля.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '7');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final saved = await harness.settingsRepo.get();
    expect(saved.reminderHour, 7);
    expect(saved.reminderMinute, 30);
    expect(harness.notifications.scheduleCalls.single, (hour: 7, minute: 30));
  });

  testWidgets('a failing schedule shows a snackbar and keeps the setting', (
    tester,
  ) async {
    final harness = Harness();
    harness.notifications.throwOnSchedule = true;
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _scrollToReminders(tester);

    await tester.tap(find.text('Включить напоминания'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось обновить напоминание'), findsOneWidget);
    expect((await harness.settingsRepo.get()).remindersEnabled, isFalse);
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

  testWidgets('shows the unavailable hint when cloud keys are missing', (
    tester,
  ) async {
    final harness = Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Синхронизация недоступна'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Синхронизация недоступна'), findsOneWidget);
  });

  testWidgets('shows login button when not authenticated', (tester) async {
    final harness = Harness(auth: FakeCloudAuthService());
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Войти через Email'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Войти через Email'), findsOneWidget);
    expect(find.text('Синхронизировать сейчас'), findsNothing);
  });

  testWidgets('shows sync button when authenticated', (tester) async {
    final harness = Harness(
      auth: FakeCloudAuthService(email: 'learner@example.com'),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Синхронизировать сейчас'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Синхронизировать сейчас'), findsOneWidget);
    expect(find.text('learner@example.com'), findsOneWidget);
  });

  testWidgets('login sends a magic link to the entered email', (tester) async {
    final auth = FakeCloudAuthService();
    final harness = Harness(auth: auth);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Войти через Email'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Войти через Email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'learner@example.com');
    await tester.tap(find.text('Отправить'));
    await tester.pumpAndSettle();

    expect(auth.requestedEmail, 'learner@example.com');
  });

  testWidgets('sync button reports what was sent and received', (tester) async {
    final sync = FakeCloudSyncService(
      report: const SyncReport(pushed: 4, pulled: 1),
    );
    final harness = Harness(
      auth: FakeCloudAuthService(email: 'learner@example.com'),
      sync: sync,
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Синхронизировать сейчас'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Синхронизировать сейчас'));
    await tester.pumpAndSettle();

    expect(sync.syncCalls, 1);
    expect(find.text('Отправлено 4, получено 1'), findsOneWidget);
  });
}
