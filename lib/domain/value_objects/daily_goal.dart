import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:meta/meta.dart';

/// Дневная цель: сделано ответов и сколько запланировано.
///
/// Собирается из `DailyStats` и лимитов `UserSettings`, чтобы экран не
/// складывал числа сам: сумма лимитов — правило домена, а не вёрстки.
@immutable
final class DailyGoal {
  /// Создаёт цель; [target] не может быть отрицательным.
  const DailyGoal({required this.stats, required this.target})
    : assert(target >= 0, 'target must be >= 0');

  /// Статистика дня или `null`, когда записей ещё нет.
  final DailyStats? stats;

  /// Сколько ответов запланировано: `dailyNewLimit + dailyReviewLimit`.
  final int target;

  /// Сколько ответов сделано сегодня.
  int get done => stats?.totalAnswers ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGoal && stats == other.stats && target == other.target;

  @override
  int get hashCode => Object.hash(stats, target);

  @override
  String toString() => 'DailyGoal(done: $done, target: $target)';
}
