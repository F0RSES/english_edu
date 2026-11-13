import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:flutter/material.dart';

/// Крупный размер цифры серии.
const _bigNumberSize = 48.0;

/// Первая веха, к которой показываем остаток.
const _firstMilestone = 7;

/// Вехи, после которых серия получает награду (ADR-015).
const _celebrateMilestone = 7;
const _fireMilestone = 30;
const _centuryMilestone = 100;
const _yearMilestone = 365;

/// Карточка серии: сколько дней подряд были занятия.
///
/// Нулевая серия — не ошибка, а приглашение начать: экран не должен выглядеть
/// сломанным у нового пользователя. Freeze не реализован (Phase 5d, BL-46) —
/// карточка честно сообщает об этом вместо неактивной кнопки.
class StreakCard extends StatelessWidget {
  /// Создаёт карточку для [streak].
  const StreakCard({required this.streak, super.key});

  /// Текущая серия.
  final StreakInfo streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = streak.count;
    final lastActive = streak.lastActiveLocalDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (count == 0)
              Text('Начни серию сегодня', style: theme.textTheme.titleMedium)
            else ...[
              Text(
                '$count',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: _bigNumberSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${pluralize(count, one: 'день', few: 'дня', many: 'дней')} '
                'подряд',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_milestoneMessage(count), style: theme.textTheme.bodyMedium),
            ],
            if (lastActive != null) ...[
              const SizedBox(height: 4),
              Text(
                'Последняя активность: $lastActive',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Freeze появится в Phase 5d',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Что показать про вехи: поздравление или остаток до первой.
  ///
  /// Награды за вехи появятся вместе с freeze (Phase 5d), поэтому здесь нет
  /// состояния — сообщение целиком выводится из [count].
  String _milestoneMessage(int count) {
    if (count >= _yearMilestone) {
      return '🎉 $_yearMilestone дней подряд!';
    }
    if (count >= _centuryMilestone) {
      return '🔥 $_centuryMilestone дней! Огонь';
    }
    if (count >= _fireMilestone) {
      return '🔥 $_fireMilestone дней! Огонь';
    }
    if (count >= _celebrateMilestone) {
      return '🎉 $_celebrateMilestone дней! Молодец';
    }
    final remaining = _firstMilestone - count;
    return 'До $_firstMilestone дней: $remaining '
        '${pluralize(remaining, one: 'день', few: 'дня', many: 'дней')}';
  }
}
