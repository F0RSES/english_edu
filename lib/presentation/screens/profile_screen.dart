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
class ProfileScreen extends ConsumerWidget {
  /// Создаёт экран.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Профиль'),
      // Явная кнопка: профиль открывается вкладкой снизу, и системного
      // «назад» у него нет — без этого из экрана не выбраться.
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Назад',
        onPressed: () => context.go('/'),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Identity(settings: ref.watch(settingsRepositoryProvider).get()),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Помощник'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/chat'),
            ),
          ),
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

/// Аватар и уровень на градиентной подложке.
class _Identity extends StatelessWidget {
  const _Identity({required this.settings});

  final Future<UserSettings> settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primary,
            child: Icon(Icons.person, size: 44, color: scheme.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learner',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<UserSettings>(
                  future: settings,
                  builder: (context, snapshot) => Text(
                    'Уровень: ${snapshot.data?.preferredLevel.label ?? 'A1'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Три метрики в тонированных карточках.
class _Stats extends StatelessWidget {
  const _Stats({required this.streak, required this.words, required this.xp});

  final AsyncValue<StreakInfo> streak;
  final AsyncValue<List<Object?>> words;
  final AsyncValue<DailyGoal> xp;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatCard(label: 'Серия', value: '${streak.value?.count ?? 0}'),
      const SizedBox(width: 12),
      _StatCard(label: 'Слов', value: '${words.value?.length ?? 0}'),
      const SizedBox(width: 12),
      _StatCard(label: 'XP', value: '${xp.value?.stats?.xpGained ?? 0}'),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Открытые достижения или аккуратная заглушка.
class _Achievements extends StatelessWidget {
  const _Achievements({required this.achievements});

  final AsyncValue<List<Achievement>> achievements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = achievements.value ?? const <Achievement>[];
    final unlocked = [
      for (final item in items)
        if (item.isUnlocked) item,
    ];
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
            if (unlocked.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Пока нет достижений. Выполняй задания!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: unlocked.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
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
