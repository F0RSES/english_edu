import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Карточка ежедневного задания (ADR-030).
///
/// Показывает цель, прогресс и кнопку награды. XP начисляет use case
/// `ClaimDailyChallenge`: виджет только вызывает его и показывает результат —
/// presentation не пишет в репозитории напрямую.
class DailyChallengeCard extends ConsumerWidget {
  /// Создаёт карточку.
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(dailyChallengeProvider)
      .when(
        // Пустая заглушка вместо спиннера: главный экран не должен мигать
        // индикатором из-за одного блока.
        data: (challenge) => _ChallengeBody(challenge: challenge),
        loading: () => const SizedBox(height: 100),
        // Ошибка задания не ломает главную: остальные блоки остаются рабочими.
        error: (error, stack) => const SizedBox.shrink(),
      );
}

class _ChallengeBody extends ConsumerWidget {
  const _ChallengeBody({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(challenge.goalType),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.goalType.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${challenge.progress}/${challenge.goalValue}',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: challenge.ratio,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            const _StreakBadge(),
            const SizedBox(height: 12),
            if (challenge.isCompleted && !challenge.isClaimed)
              FilledButton(
                onPressed: () => _claim(context, ref),
                child: Text('Забрать +${challenge.xpReward} XP'),
              )
            else if (challenge.isClaimed)
              Text(
                '✓ Выполнено',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Забирает награду через use case и сообщает результат.
  ///
  /// Messenger и контейнер берутся **до** `await`: пока идёт запись, карточка
  /// успевает перестроиться, и `context.mounted` после await оказывается
  /// false — тогда терялись и SnackBar, и инвалидация (найдено
  /// integration-тестом Phase 16a).
  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);

    final int xp;
    try {
      xp = await ref.read(claimDailyChallengeProvider)();
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось забрать награду')),
      );
      return;
    }
    if (xp == 0) {
      return;
    }

    // XP входит в дневную цель, а серия челленджей выросла: без инвалидации
    // главная показывала бы старые числа до перезапуска.
    container
      ..invalidate(dailyChallengeProvider)
      ..invalidate(dailyGoalProvider)
      ..invalidate(challengeStreakProvider);

    await HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(content: Text('+$xp XP')));
  }

  static IconData _iconFor(DailyChallengeType type) => switch (type) {
    DailyChallengeType.review20 => Icons.repeat,
    DailyChallengeType.streak10 => Icons.local_fire_department,
    DailyChallengeType.new5 => Icons.auto_awesome,
    DailyChallengeType.noMistakes => Icons.verified,
  };
}

/// Бейдж серии выполненных заданий (ADR-032).
///
/// Второй контур мотивации рядом с основной серией дней: показывает текущую
/// серию челленджей и лучший результат. Ошибка чтения серии не ломает
/// карточку — бейдж просто не рисуется.
class _StreakBadge extends ConsumerWidget {
  const _StreakBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(challengeStreakProvider)
      .when(
        data: (streak) => _build(context, streak),
        loading: () => const SizedBox.shrink(),
        error: (error, stack) => const SizedBox.shrink(),
      );

  Widget _build(BuildContext context, ChallengeStreak streak) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.secondary,
    );
    // Склонение по числу: «1 день», «3 дня», «5 дней».
    final days = pluralize(
      streak.current,
      one: 'день',
      few: 'дня',
      many: 'дней',
    );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text('Серия: ${streak.current} $days', style: style),
          ],
        ),
        Text('Лучший: ${streak.best}', style: style),
      ],
    );
  }
}
