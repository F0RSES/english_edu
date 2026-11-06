import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/daily_goal.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/presentation/widgets/analytics_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Профиль — витрина успехов: кто я, сколько сделал, что открыл (Phase 20).
///
/// Настроек здесь нет: они переехали в `SettingsScreen`. Экран отвечает на
/// вопрос «как у меня дела», а не «что я могу покрутить».
class ProfileScreen extends ConsumerWidget {
  /// Создаёт экран.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider).get();
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Identity(settings: settings),
            const SizedBox(height: 16),
            _Stats(
              streak: ref.watch(computeStreakProvider),
              words: ref.watch(dictionaryEntriesProvider),
              xp: ref.watch(dailyGoalProvider),
            ),
            const SizedBox(height: 16),
            _Achievements(achievements: ref.watch(achievementsProvider)),
            const SizedBox(height: 16),
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: AnalyticsSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Аватар, подпись и текущий уровень.
class _Identity extends StatelessWidget {
  const _Identity({required this.settings});

  final Future<UserSettings> settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: 44,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Learner',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<UserSettings>(
          future: settings,
          builder: (context, snapshot) {
            final label = snapshot.data?.preferredLevel.label ?? 'A1';
            return Chip(label: Text('Уровень: $label'));
          },
        ),
      ],
    );
  }
}

/// Три числа: серия, словарь, XP за сегодня.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.streak,
    required this.words,
    required this.xp,
  });

  final AsyncValue<StreakInfo> streak;
  final AsyncValue<List<Object?>> words;
  final AsyncValue<DailyGoal> xp;

  @override
  Widget build(BuildContext context) {
    final streakValue = streak.value?.count ?? 0;
    final wordsValue = words.value?.length ?? 0;
    final xpToday = xp.value?.stats?.xpGained ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _StatColumn(label: 'Streak', value: '$streakValue'),
            _StatColumn(label: 'Слов', value: '$wordsValue'),
            _StatColumn(label: 'XP сегодня', value: '$xpToday'),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Последние достижения и переход к полному списку.
class _Achievements extends StatelessWidget {
  const _Achievements({required this.achievements});

  final AsyncValue<List<Achievement>> achievements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = achievements.value ?? const <Achievement>[];
    final unlocked = [for (final item in items) if (item.isUnlocked) item];
    final total = items.isEmpty ? 9 : items.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Достижения (${unlocked.length}/$total)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/achievements'),
                  child: const Text('Все >'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: unlocked.isEmpty ? 1 : unlocked.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (unlocked.isEmpty) {
                    return const Center(
                      child: Text('Пока нет достижений'),
                    );
                  }
                  final item = unlocked[index];
                  return SizedBox(
                    width: 88,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.type.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.type.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
