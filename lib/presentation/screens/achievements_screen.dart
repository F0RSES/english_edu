import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран достижений: что открыто и что ещё в процессе (ADR-035).
class AchievementsScreen extends ConsumerWidget {
  /// Создаёт экран.
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: stored.when(
        data: (items) => _buildBody(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Не удалось загрузить достижения')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Achievement> items) {
    final unlocked = [for (final item in items) if (item.isUnlocked) item];
    final inProgress = [for (final item in items) if (!item.isUnlocked) item];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Разблокировано (${unlocked.length})'),
        const SizedBox(height: 12),
        if (unlocked.isEmpty)
          const Text('Пока пусто — начни с серии дней.')
        else
          _grid(unlocked),
        const SizedBox(height: 24),
        _SectionHeader('В процессе (${inProgress.length})'),
        const SizedBox(height: 12),
        if (inProgress.isEmpty)
          const Text('Все достижения открыты!')
        else
          _grid(inProgress),
      ],
    );
  }

  Widget _grid(List<Achievement> items) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
    ),
    itemCount: items.length,
    itemBuilder: (context, index) => _AchievementCard(item: items[index]),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );
}

/// Карточка одного достижения: иконка, название и прогресс.
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final Achievement item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unlocked = item.isUnlocked;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: unlocked ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.type.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            item.type.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked ? '✓' : '${item.progress}/${item.type.goal}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: unlocked ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
