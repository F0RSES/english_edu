import 'dart:math' as math;

import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/streak_info.dart';
import 'package:english_edu/domain/value_objects/streak_rule.dart';

/// Сколько дней назад максимум смотрим при расчёте серии.
///
/// 10 лет покрывают любой реалистичный streak. Серия длиннее [_lookbackDays]
/// без активности сегодня даст `lastActive = null` — зафиксировано, приемлемо.
const _lookbackDays = 3650;

/// Считает streak по DailyStats с учётом заморозок (ADR-015).
///
/// Пропуск покрывается freeze: день без ответов, но с заморозкой продолжает
/// серию, и серия не рвётся. Заморозки зарабатываются вехами, но не выдаются
/// автоматически — `StreakInfo.frozenAvailable` показывает остаток.
///
/// Использует локальную календарную дату момента `clock()` — ту же дату
/// `DailyStats`, которую пишет `RecordReview` через `now.toLocal()`.
///
/// 3 запроса к БД независимо от длины истории: `getLastActiveDate`,
/// `getRange` и `FrozenDaysRepository.getAll`.
final class ComputeStreak {
  /// Creates the use case.
  const ComputeStreak({
    required StatsRepository stats,
    required FrozenDaysRepository frozen,
    required DateTime Function() clock,
  }) : _stats = stats,
       _frozen = frozen,
       _clock = clock;

  final StatsRepository _stats;
  final FrozenDaysRepository _frozen;
  final DateTime Function() _clock;

  /// Returns the current streak and the most recent active day.
  ///
  /// Серия считается только от сегодняшнего дня назад: если сегодня ответов
  /// не было и день не заморожен, [StreakInfo.count] равен нулю, а
  /// [StreakInfo.lastActiveLocalDate] указывает на последнюю активную дату.
  Future<StreakInfo> call() async {
    final today = LocalDate.fromDateTime(_clock().toLocal());
    final frozen = await _frozen.getAll();
    final lastActive = await _stats.getLastActiveDate();
    if (lastActive == null || lastActive.compareTo(today) > 0) {
      return StreakInfo(count: 0, frozenDates: frozen);
    }

    final from = today.addDays(-_lookbackDays);
    final range = await _stats.getRange(from, today);
    final byDate = {for (final stats in range) stats.date: stats};

    var day = today;
    var count = 0;
    while (day.compareTo(from) >= 0) {
      final hadAnswers = (byDate[day]?.totalAnswers ?? 0) > 0;
      if (!hadAnswers && !frozen.contains(day)) {
        break;
      }
      count++;
      day = day.addDays(-1);
    }

    // Заработано вехами минус израсходовано. Нижняя граница — 0: заморозок
    // может быть больше, чем заработано (например, после сброса серии).
    final rawAvailable = StreakRule.frozenEarnedFor(count) - frozen.length;
    final available = math.max(
      0,
      math.min(StreakRule.maxAvailable, rawAvailable),
    );

    return StreakInfo(
      count: count,
      lastActiveLocalDate: lastActive,
      frozenAvailable: available,
      frozenDates: frozen,
    );
  }
}
