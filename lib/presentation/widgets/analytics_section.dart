import 'package:english_edu/core/di/providers.dart';
import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/value_objects/analytics.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Высота самого высокого столбца графика.
const _chartHeight = 72.0;

/// Минимальная видимая высота столбца: пустой день тоже должен читаться.
const _minBarHeight = 4.0;

/// Дашборд прогресса для `ProfileScreen` (ADR-021).
///
/// Только читает: плитки статусов, график за 7 дней, самые проваливаемые слова
/// и прогноз полного mastery. Данные приходят из [analyticsProvider], поэтому
/// экран не пересчитывает ничего сам.
class AnalyticsSection extends ConsumerWidget {
  /// Создаёт секцию.
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(analyticsProvider)
      .when(
        data: (analytics) => _AnalyticsView(analytics: analytics),
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Не удалось загрузить аналитику'),
        ),
      );
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({required this.analytics});

  final Analytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MetricTile(label: 'Всего', value: analytics.totalWords),
            _MetricTile(label: 'Выучено', value: analytics.masteredCount),
            _MetricTile(label: 'Изучаю', value: analytics.learningCount),
            _MetricTile(label: 'Новые', value: analytics.newCount),
          ],
        ),
        const SizedBox(height: 16),
        Text('За 7 дней', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _WeekChart(days: analytics.last7Days),
        const SizedBox(height: 16),
        Text('Трудные слова', style: theme.textTheme.titleSmall),
        if (analytics.hardestWords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Пока нет провалов',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final item in analytics.hardestWords)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.word.term),
              trailing: Text('${item.lapses} ${_lapsesLabel(item.lapses)}'),
            ),
        const SizedBox(height: 8),
        Text(
          _projectionLabel(analytics.projectedMasteryDate),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// «1 провал», «2 провала», «5 провалов».
  String _lapsesLabel(int lapses) =>
      pluralize(lapses, one: 'провал', few: 'провала', many: 'провалов');

  /// Прогноз в формате `DD.MM.YYYY`; null — «—».
  String _projectionLabel(LocalDate? date) {
    if (date == null) {
      return 'Прогноз mastery: —';
    }
    final iso = date.toString(); // YYYY-MM-DD
    final parts = iso.split('-');
    return 'Все слова mastered к ${parts[2]}.${parts[1]}.${parts[0]}';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(
              '$value',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Столбцы по дням: высота пропорциональна числу ответов, под ними день недели.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<DailyStats> days;

  static const _labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  double _heightFor(DailyStats day, int maxAnswers) {
    if (maxAnswers == 0) {
      return _minBarHeight;
    }
    return _minBarHeight +
        (_chartHeight - _minBarHeight) * day.totalAnswers / maxAnswers;
  }

  String _labelFor(DailyStats day) {
    final date = DateTime.utc(1970)
        .add(Duration(days: day.date.daysSinceEpoch));
    return _labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    var maxAnswers = 0;
    for (final day in days) {
      if (day.totalAnswers > maxAnswers) {
        maxAnswers = day.totalAnswers;
      }
    }
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return SizedBox(
      height: _chartHeight + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, day) in days.indexed)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Bar(
                    key: ValueKey('bar-${day.date}'),
                    height: _heightFor(day, maxAnswers),
                    delayIndex: index,
                    isEmpty: day.totalAnswers == 0,
                  ),
                  const SizedBox(height: 4),
                  Text(_labelFor(day), style: labelStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Один столбец: аккуратный цилиндр, растущий снизу вверх.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.delayIndex,
    required this.isEmpty,
    super.key,
  });

  final double height;
  final int delayIndex;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
          width: 12,
          height: height,
          decoration: BoxDecoration(
            // Пустой день виден, но не спорит с данными.
            color: isEmpty ? scheme.outlineVariant : scheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        )
        .animate(delay: (delayIndex * 40).ms)
        .scaleY(
          begin: 0,
          end: 1,
          alignment: Alignment.bottomCenter,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
