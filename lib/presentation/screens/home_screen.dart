import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/presentation/widgets/daily_goal_card.dart';
import 'package:english_edu/presentation/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Главный экран: серия дней, дневная цель и запуск урока.
///
/// Экран ничего не считает сам: серию отдаёт `ComputeStreak`, очередь —
/// `GetTodayQueue`, план дня — сумма лимитов из `UserSettings`.
class HomeScreen extends ConsumerWidget {
  /// Создаёт экран.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = LocalDate.fromDateTime(ref.watch(clockProvider)().toLocal());
    return Scaffold(
      appBar: AppBar(
        title: const Text('English Edu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      // Прокрутка, а не голый Column: на низких экранах (и в ландшафте)
      // карточки плюс две кнопки игр не влезают в высоту.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AsyncValue.when, а не FutureBuilder: кэшем владеет
            // FutureProvider, поэтому ref.invalidate после урока
            // действительно пересчитывает данные.
            ref
                .watch(computeStreakProvider)
                .when(
                  data: (streak) => StreakCard(streak: streak, today: today),
                  loading: () => StreakCard(
                    streak: const StreakInfo(count: 0),
                    today: today,
                  ),
                  error: (error, stack) => StreakCard(
                    streak: const StreakInfo(count: 0),
                    today: today,
                  ),
                ),
            const SizedBox(height: 12),
            ref
                .watch(dailyGoalProvider)
                .when(
                  data: (goal) => DailyGoalCard(
                    stats: goal.stats,
                    totalTarget: goal.target,
                  ),
                  loading: () =>
                      DailyGoalCard(stats: null, totalTarget: _fallbackTarget),
                  error: (error, stack) =>
                      DailyGoalCard(stats: null, totalTarget: _fallbackTarget),
                ),
            const SizedBox(height: 24),
            ref
                .watch(getTodayQueueProvider)
                .when(
                  data: (queue) => _buildStart(context, queue),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => OutlinedButton.icon(
                    onPressed: () => _retry(ref),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/error-hunter'),
              icon: const Icon(Icons.games_outlined),
              label: const Text('Играть в Error Hunter'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/cloze-test'),
              icon: const Icon(Icons.text_fields),
              label: const Text('Заполни пропуск'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/word-scramble'),
              icon: const Icon(Icons.abc),
              label: const Text('Собери слово'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/listening'),
              icon: const Icon(Icons.hearing),
              label: const Text('Аудио-диктант'),
            ),
            // Бейдж проблемных слов: кнопка появляется только когда есть что
            // повторять, иначе вела бы на пустой экран (ADR-026).
            ref
                .watch(weakWordsCountProvider)
                .when(
                  data: (count) => count == 0
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/weak-words'),
                            icon: const Icon(Icons.bolt, color: Colors.orange),
                            label: Text('Повторить сложные ($count)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) => _openSection(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Словарь',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  /// Перезапрашивает данные главного экрана.
  ///
  /// Инвалидация `FutureProvider` сбрасывает кэш и запускает пересчёт при
  /// следующем чтении — репозитории пересоздавать не нужно.
  void _retry(WidgetRef ref) {
    ref
      ..invalidate(computeStreakProvider)
      ..invalidate(getTodayQueueProvider)
      ..invalidate(dailyGoalProvider);
  }

  /// Кнопка старта: выключена, когда очередь пуста.
  Widget _buildStart(BuildContext context, TodayQueue queue) {
    if (queue.length == 0) {
      return const FilledButton(
        onPressed: null,
        child: Text('Все слова изучены'),
      );
    }
    final words = pluralize(
      queue.length,
      one: 'слово',
      few: 'слова',
      many: 'слов',
    );
    return FilledButton(
      onPressed: () => context.go('/lesson'),
      child: Text('Начать урок (${queue.length} $words)'),
    );
  }

  /// План по умолчанию, пока настройки не прочитаны.
  ///
  /// Показывать «0 / 0» нельзя: это выглядит как отсутствие цели.
  int get _fallbackTarget {
    final defaults = UserSettings.defaults();
    return defaults.dailyNewLimit + defaults.dailyReviewLimit;
  }

  void _openSection(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('/dictionary');
      case 2:
        context.go('/profile');
      default:
        context.go('/');
    }
  }
}
