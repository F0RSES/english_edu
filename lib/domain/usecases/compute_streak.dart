import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';

/// Сколько дней назад максимум смотрим при расчёте серии.
///
/// 10 лет покрывают любой реалистичный streak. Серия длиннее [_lookbackDays]
/// без активности сегодня даст `lastActive = null` — зафиксировано, приемлемо.
const _lookbackDays = 3650;

/// Считает streak по DailyStats. День без ответов обрывает серию.
/// Freeze не учитывается (Phase 5).
///
/// Использует локальную календарную дату момента `clock()` — ту же дату
/// `DailyStats`, которую пишет `RecordReview` через `now.toLocal()`.
///
/// 2 запроса к БД независимо от длины истории: один
/// [StatsRepository.getLastActiveDate] и один [StatsRepository.getRange].
final class ComputeStreak {
  /// Creates the use case.
  const ComputeStreak({
    required StatsRepository stats,
    required DateTime Function() clock,
  }) : _stats = stats,
       _clock = clock;

  final StatsRepository _stats;
  final DateTime Function() _clock;

  /// Returns the current streak and the most recent active day.
  ///
  /// Серия считается только от сегодняшнего дня назад: если сегодня ответов
  /// не было, [StreakInfo.count] равен нулю, а [StreakInfo.lastActiveLocalDate]
  /// указывает на последнюю активную дату из истории.
  Future<StreakInfo> call() async {
    final today = LocalDate.fromDateTime(_clock().toLocal());
    final lastActive = await _stats.getLastActiveDate();
    if (lastActive == null || lastActive.compareTo(today) > 0) {
      return const StreakInfo(count: 0);
    }

    final from = today.addDays(-_lookbackDays);
    final range = await _stats.getRange(from, today);
    final byDate = {for (final stats in range) stats.date: stats};

    var day = today;
    var count = 0;
    while (day.compareTo(from) >= 0 && (byDate[day]?.totalAnswers ?? 0) > 0) {
      count++;
      day = day.addDays(-1);
    }

    return StreakInfo(count: count, lastActiveLocalDate: lastActive);
  }
}
