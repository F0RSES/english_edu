import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
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

/// Подпись бейджа «заморозка уже потрачена».
const _freezeUsedLabel = 'Freeze использован';

/// Карточка серии: сколько дней подряд были занятия.
///
/// Нулевая серия — не ошибка, а приглашение начать: экран не должен выглядеть
/// сломанным у нового пользователя.
///
/// Заморозки (ADR-015): показывает остаток `frozenAvailable` и, если одна из
/// них израсходована за последние [_recentFreezeDays] дней, бейдж «Freeze
/// использован». [today] нужен только для этой проверки — дату приносит экран,
/// чтобы виджет не читал системные часы.
class StreakCard extends StatelessWidget {
  /// Создаёт карточку для [streak] на дату [today].
  const StreakCard({required this.streak, required this.today, super.key});

  /// Текущая серия.
  final StreakInfo streak;

  /// Локальная дата экрана: граница «недавности» заморозки.
  final LocalDate today;

  /// Окно, в котором израсходованная заморозка считается свежей.
  static const int _recentFreezeDays = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = streak.count;
    final freezes = streak.frozenAvailable;
    final freezeWord = pluralize(
      freezes,
      one: 'заморозка',
      few: 'заморозки',
      many: 'заморозок',
    );
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
              '🧊 $freezes $freezeWord доступно',
              style: theme.textTheme.bodyMedium,
            ),
            if (_hasRecentFreeze) ...[
              const SizedBox(height: 4),
              const Chip(
                label: Text(_freezeUsedLabel),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Была ли заморозка израсходована в последние [_recentFreezeDays] дней.
  ///
  /// Смотрим назад от [today], а не «любая дата в наборе»: иначе бейдж висел
  /// бы вечно после первого пропуска.
  bool get _hasRecentFreeze {
    final from = today.addDays(-_recentFreezeDays);
    return streak.frozenDates.any(
      (date) => date.compareTo(from) >= 0 && date.compareTo(today) <= 0,
    );
  }

  /// Что показать про вехи: поздравление или остаток до первой.
  ///
  /// Сообщение целиком выводится из [count]: собственного состояния у
  /// карточки нет.
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
