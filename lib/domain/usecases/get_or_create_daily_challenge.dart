import 'dart:math';

import 'package:english_edu/domain/repositories/daily_challenge_repository.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Возвращает задание на сегодня, создавая его при первом обращении за день
/// (Phase 15b, ADR-030).
///
/// Тип выбирается случайно один раз и дальше живёт в БД: при повторном
/// открытии экрана задание не меняется, иначе цель «переизбиралась» бы до
/// удобной.
final class GetOrCreateDailyChallenge {
  /// Создаёт use case.
  const GetOrCreateDailyChallenge({
    required DailyChallengeRepository repo,
    required DateTime Function() clock,
    required Random random,
  }) : _repo = repo,
       _clock = clock,
       _random = random;

  final DailyChallengeRepository _repo;
  final DateTime Function() _clock;
  final Random _random;

  /// Возвращает сегодняшнее задание; создаёт и сохраняет, если его нет.
  Future<DailyChallenge> call() async {
    // День считается по локальному времени пользователя: задание привязано к
    // календарной дате, а не к мгновению.
    final today = LocalDate.fromDateTime(_clock().toLocal());
    final existing = await _repo.getForDate(today);
    if (existing != null) {
      return existing;
    }

    final type = DailyChallengeType.random(_random);
    final created = DailyChallenge(
      date: today,
      goalType: type,
      goalValue: type.goal,
      progress: 0,
      xpReward: type.xp,
    );
    await _repo.save(created);
    return created;
  }
}
