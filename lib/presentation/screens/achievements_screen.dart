import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран достижений: что открыто и что ещё в процессе (ADR-035).
class AchievementsScreen extends ConsumerWidget {
  /// Создаёт экран.
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored = ref.watch(achievementsProvider);
    final lang = ref.watch(languageProvider).value ?? AppLanguage.ru;
    return Scaffold(
      appBar: AppBar(title: Text(S.achievementsTitle(lang))),
      body: stored.when(
        data: (items) => _buildBody(context, items, lang),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(S.achievementsLoadFailed(lang))),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Achievement> items,
    AppLanguage lang,
  ) {
    final unlocked = [
      for (final item in items)
        if (item.isUnlocked) item,
    ];
    final inProgress = [
      for (final item in items)
        if (!item.isUnlocked) item,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(S.achievementsUnlocked(unlocked.length, lang)),
        const SizedBox(height: 12),
        if (unlocked.isEmpty)
          Text(S.achievementsEmptyUnlocked(lang))
        else
          _grid(unlocked, lang),
        const SizedBox(height: 24),
        _SectionHeader(S.achievementsInProgress(inProgress.length, lang)),
        const SizedBox(height: 12),
        if (inProgress.isEmpty)
          Text(S.achievementsAllUnlocked(lang))
        else
          _grid(inProgress, lang),
      ],
    );
  }

  Widget _grid(List<Achievement> items, AppLanguage lang) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
    ),
    itemCount: items.length,
    itemBuilder: (context, index) =>
        _AchievementCard(item: items[index], lang: lang),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.bold),
  );
}

/// Карточка одного достижения: иконка, название и прогресс.
class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item, required this.lang});

  final Achievement item;
  final AppLanguage lang;

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
            S.achievementTitle(item.type, lang),
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
