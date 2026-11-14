import 'package:english_edu/core/localization/strings.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:flutter/material.dart';

/// Карточка дневной цели: сделано ответов из суточного плана.
///
/// План — сумма лимитов новых слов и повторений (`dailyNewLimit +
/// dailyReviewLimit`), поэтому [totalTarget] приходит снаружи: карточка не
/// знает про настройки.
class DailyGoalCard extends StatelessWidget {
  /// Создаёт карточку; [stats] равен `null`, когда за день ничего не сделано.
  const DailyGoalCard({
    required this.stats,
    required this.totalTarget,
    this.lang = AppLanguage.ru,
    super.key,
  });

  /// Статистика за сегодня или `null`, если записи ещё нет.
  final DailyStats? stats;

  /// Сколько ответов запланировано на день.
  final int totalTarget;

  /// Язык интерфейса; ru по умолчанию (Phase 27b).
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = stats?.totalAnswers ?? 0;
    // Полоска не выходит за 100%, а счётчик показывает факт: перебор видно
    // по тексту «7 / 5», но бар не врёт про остаток.
    final progress = totalTarget <= 0
        ? 0.0
        : (done >= totalTarget ? 1.0 : done / totalTarget);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.wordsToday(done, totalTarget, lang),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}
