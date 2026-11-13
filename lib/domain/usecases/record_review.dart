import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/srs/srs_calculator.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/review_outcome.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/xp_rules.dart';

/// Порог mastery по числу успешных повторений подряд.
const _masteryRepetitions = 5;

/// Порог mastery по длине интервала в днях (Anki-style mature).
const _masteryIntervalDays = 21;

/// Записывает один ответ: пересчитывает карточку, пишет лог и статистику.
///
/// Атомарность (progress + log + stats в одной транзакции) — ответственность
/// реализации репозитория в Phase 2. Use case не транзакционный: каждый вызов
/// выполняется отдельно.
final class RecordReview {
  /// Creates the use case.
  const RecordReview({
    required ProgressRepository progress,
    required ReviewLogRepository reviewLog,
    required StatsRepository stats,
    required WordRepository words,
    required SrsCalculator srs,
    required ReviewLogId Function() nextLogId,
    required DateTime Function() clock,
  })  : _progress = progress,
        _reviewLog = reviewLog,
        _stats = stats,
        _words = words,
        _srs = srs,
        _nextLogId = nextLogId,
        _clock = clock;

  final ProgressRepository _progress;
  final ReviewLogRepository _reviewLog;
  final StatsRepository _stats;
  final WordRepository _words;
  final SrsCalculator _srs;
  final ReviewLogId Function() _nextLogId;
  final DateTime Function() _clock;

  /// Records the answer of [grade] for [wordId].
  ///
  /// Throws [ArgumentError] when the word does not exist.
  Future<ReviewOutcome> call(WordId wordId, ReviewGrade grade) async {
    final now = _clock().toUtc();
    final word = await _words.getById(wordId);
    if (word == null) {
      throw ArgumentError.value(wordId, 'wordId', 'word does not exist');
    }

    final existing = await _progress.getByWordId(wordId);
    final current = existing ?? WordProgress.newWord(wordId: wordId, now: now);
    final next = _srs.apply(current.cardState, grade, now);

    await _progress.upsert(
      current.copyWith(
        cardState: next,
        status: _deriveStatus(next),
        lastReviewedAt: now,
      ),
    );
    await _reviewLog.append(
      ReviewLog(
        id: _nextLogId(),
        wordId: wordId,
        reviewedAt: now,
        grade: grade,
        previousCardState: current.cardState,
        newCardState: next,
      ),
    );
    final xpGained = XpRules.forGrade(grade);
    final isCorrect = XpRules.isCorrect(grade);
    await _bumpStats(now, xpGained, isCorrect);
    return ReviewOutcome(
      newCardState: next,
      xpGained: xpGained,
      isCorrect: isCorrect,
    );
  }

  /// mastered при `reps >= 5 && intervalDays >= 21` (Anki-style mature +
  /// reps floor). `lapses` не блокирует — слово с историей провалов может
  /// стать mastered при достаточной серии.
  WordStatus _deriveStatus(CardState card) {
    if (card.repetitions >= _masteryRepetitions &&
        card.intervalDays >= _masteryIntervalDays) {
      return WordStatus.mastered;
    }
    // Метод вызывается только после ответа: слово уже видели, поэтому
    // минимум learning — даже если repetitions сбросились провалом.
    return WordStatus.learning;
  }

  Future<void> _bumpStats(DateTime now, int xpGained, bool isCorrect) async {
    // Календарный день считается по локальному времени пользователя:
    // LocalDate берёт Y/M/D из переданного DateTime, поэтому нужен toLocal().
    final today = LocalDate.fromDateTime(now.toLocal());
    final current = await _stats.getForDate(today) ?? DailyStats.empty(today);
    await _stats.upsert(
      current.copyWith(
        reviewsCompleted: current.reviewsCompleted + 1,
        xpGained: current.xpGained + xpGained,
        correctAnswers: current.correctAnswers + (isCorrect ? 1 : 0),
      ),
    );
  }
}
