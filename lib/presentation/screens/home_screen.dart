import 'dart:async';

import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/presentation/widgets/daily_challenge_card.dart';
import 'package:english_edu/presentation/widgets/daily_goal_card.dart';
import 'package:english_edu/presentation/widgets/streak_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Главный экран: статистика, старт урока, тренировки и задание дня.
///
/// Экран ничего не считает сам: серию отдаёт `ComputeStreak`, очередь —
/// `GetTodayQueue`, план дня — сумма лимитов из `UserSettings`.
class HomeScreen extends ConsumerWidget {
  /// Создаёт экран.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = LocalDate.fromDateTime(ref.watch(clockProvider)().toLocal());
    final weakCount = ref.watch(weakWordsCountProvider).value ?? 0;
    final smartCount = ref.watch(smartReviewCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('English Edu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            // push: экран открывается поверх главной, поэтому в AppBar
            // появляется кнопка «Назад» (Phase 17).
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dailyGoalProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildStreak(ref, today)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGoal(ref)),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              _buildHero(context, ref),
              const SizedBox(height: 16),
              if (weakCount > 0 || smartCount > 0) ...[
                Row(
                  children: [
                    if (weakCount > 0)
                      Expanded(
                        child: _PillButton(
                          icon: Icons.bolt,
                          label: 'Сложные ($weakCount)',
                          color: Colors.orange,
                          onTap: () => context.push('/weak-words'),
                        ),
                      ),
                    if (weakCount > 0 && smartCount > 0)
                      const SizedBox(width: 12),
                    if (smartCount > 0)
                      Expanded(
                        child: _PillButton(
                          icon: Icons.auto_awesome,
                          label: 'Smart ($smartCount)',
                          color: Colors.purple,
                          onTap: () => context.push('/smart-review'),
                        ),
                      ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 24),
              ],
              Text(
                'Тренировки',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
              const SizedBox(height: 12),
              _buildGames(context)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: 24),
              const DailyChallengeCard().animate().fadeIn(
                delay: 350.ms,
                duration: 300.ms,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        tooltip: 'Помощник',
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.smart_toy),
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

  /// Компактная карточка серии: пока данные грузятся, показываем нулевую.
  Widget _buildStreak(WidgetRef ref, LocalDate today) => ref
      .watch(computeStreakProvider)
      .when(
        data: (streak) => StreakCard(streak: streak, today: today),
        loading: () =>
            StreakCard(streak: const StreakInfo(count: 0), today: today),
        error: (error, stack) =>
            StreakCard(streak: const StreakInfo(count: 0), today: today),
      );

  Widget _buildGoal(WidgetRef ref) => ref
      .watch(dailyGoalProvider)
      .when(
        data: (goal) =>
            DailyGoalCard(stats: goal.stats, totalTarget: goal.target),
        loading: () => DailyGoalCard(stats: null, totalTarget: _fallbackTarget),
        error: (error, stack) =>
            DailyGoalCard(stats: null, totalTarget: _fallbackTarget),
      );

  /// Hero-кнопка урока: активность решает очередь дня.
  Widget _buildHero(BuildContext context, WidgetRef ref) => ref
      .watch(getTodayQueueProvider)
      .when(
        data: (queue) => _HeroStartButton(
          queue: queue,
          onTap: () =>
              _openGame(context, '/lesson', HapticFeedback.mediumImpact),
        ),
        loading: () => const _HeroStartButton(queue: null, onTap: null),
        error: (error, stack) => OutlinedButton.icon(
          onPressed: () => _retry(ref),
          icon: const Icon(Icons.refresh),
          label: const Text('Повторить'),
        ),
      );

  Widget _buildGames(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.3,
    children: [
      _GameCard(
        title: 'Error Hunter',
        icon: Icons.bug_report,
        color: Colors.redAccent,
        onTap: () =>
            _openGame(context, '/error-hunter', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Пропуск',
        icon: Icons.edit_note,
        color: Colors.blueAccent,
        onTap: () =>
            _openGame(context, '/cloze-test', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Собери слово',
        icon: Icons.abc,
        color: Colors.green,
        onTap: () =>
            _openGame(context, '/word-scramble', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Memory',
        icon: Icons.memory,
        color: Colors.indigo,
        onTap: () =>
            _openGame(context, '/word-match', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Typing',
        icon: Icons.keyboard,
        color: Colors.cyan,
        onTap: () =>
            _openGame(context, '/typing-speed', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Разговорник',
        icon: Icons.forum,
        color: Colors.teal,
        onTap: () =>
            _openGame(context, '/phrasebook', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Диктант',
        icon: Icons.hearing,
        color: Colors.orange,
        onTap: () =>
            _openGame(context, '/listening', HapticFeedback.selectionClick),
      ),
      _GameCard(
        title: 'Чтение',
        icon: Icons.book,
        color: Colors.deepPurple,
        onTap: () =>
            _openGame(context, '/reading', HapticFeedback.selectionClick),
      ),
    ],
  );

  /// Тактильный отклик и переход.
  ///
  /// Отклик не ожидается: навигация не должна зависеть от платформенного
  /// канала — в тестах его нет, и `await` оставлял экран на месте.
  void _openGame(
    BuildContext context,
    String route,
    Future<void> Function() feedback,
  ) {
    unawaited(feedback());
    unawaited(context.push(route));
  }

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(computeStreakProvider)
      ..invalidate(getTodayQueueProvider)
      ..invalidate(dailyGoalProvider);
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

/// Крупная кнопка старта урока: градиент, иконка и счётчик слов.
class _HeroStartButton extends StatelessWidget {
  const _HeroStartButton({required this.queue, required this.onTap});

  /// Очередь дня; null — данные ещё грузятся.
  final TodayQueue? queue;

  /// Что делать по тапу; null — кнопка недоступна.
  final VoidCallback? onTap;

  bool get _isEmpty => queue == null || queue!.length == 0;

  String get _subtitle {
    final value = queue;
    if (value == null) {
      return 'Загрузка…';
    }
    if (value.length == 0) {
      return 'Все слова изучены';
    }
    final words = pluralize(
      value.length,
      one: 'слово',
      few: 'слова',
      many: 'слов',
    );
    return '${value.length} $words';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: _isEmpty ? null : onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.play_arrow, size: 48, color: scheme.onPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Начать урок',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        style: TextStyle(fontSize: 14, color: scheme.onPrimary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Второстепенная кнопка-«таблетка» для режимов повторения.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, color: color, size: 18),
    label: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: BorderSide(color: color.withAlpha(128)),
    ),
  );
}

/// Плитка игры в сетке «Тренировки».
class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
