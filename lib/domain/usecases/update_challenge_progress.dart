import 'package:english_edu/domain/repositories/daily_challenge_repository.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';

/// Двигает прогресс сегодняшнего задания после ответа (ADR-030).
///
/// Вызывается из `RecordReview`, поэтому покрывает все пути ответа: урок,
/// слабые слова, диктант и scramble. Ошибки наружу не глушит — это делает
/// вызывающая сторона, чтобы челлендж не ломал SRS.
final class UpdateChallengeProgress {
  /// Создаёт use case.
  const UpdateChallengeProgress({
    required DailyChallengeRepository repo,
    required DateTime Function() clock,
  }) : _repo = repo,
       _clock = clock;

  final DailyChallengeRepository _repo;
  final DateTime Function() _clock;

  /// Применяет один ответ к заданию дня.
  ///
  /// [isFirstResponse] — ответ по слову, у которого не было прогресса: нужно
  /// только для `new5`. Ничего не делает, если задания на сегодня нет или
  /// оно уже выполнено.
  ///
  /// Не бросает наружу: сбой задания дня не должен откатывать записанный
  /// ответ и ломать SRS (ADR-030). Проглоченная ошибка означает лишь то, что
  /// карточка не сдвинулась.
  Future<void> call({
    required ReviewGrade grade,
    required bool isFirstResponse,
  }) async {
    try {
      final today = LocalDate.fromDateTime(_clock().toLocal());
      final existing = await _repo.getForDate(today);
      if (existing == null || existing.isCompleted) {
        return;
      }

      final next = _advance(
        existing,
        grade: grade,
        isFirstResponse: isFirstResponse,
      );
      if (next == existing.progress) {
        // `hard` в noMistakes нейтрален: писать в БД нечего.
        return;
      }

      await _repo.save(
        existing.copyWith(
          progress: next,
          completedAt: next >= existing.goalValue ? _clock().toUtc() : null,
        ),
      );
    } on Object {
      // Вспомогательный шаг: ошибка БД задания не откатывает ответ.
      return;
    }
  }

  /// Считает новый прогресс по правилам типа задания.
  int _advance(
    DailyChallenge challenge, {
    required ReviewGrade grade,
    required bool isFirstResponse,
  }) {
    switch (challenge.goalType) {
      case DailyChallengeType.review20:
        return challenge.progress + 1;
      case DailyChallengeType.streak10:
        return grade.isFailure ? 0 : challenge.progress + 1;
      case DailyChallengeType.new5:
        return isFirstResponse ? challenge.progress + 1 : challenge.progress;
      case DailyChallengeType.noMistakes:
        if (grade.isFailure) {
          return 0;
        }
        if (grade == ReviewGrade.hard) {
          // Ни +1, ни сброс: «без ошибок» прощает трудный ответ, но не считает
          // его за чистый.
          return challenge.progress;
        }
        return challenge.progress + 1;
    }
  }
}
