import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:english_edu/domain/value_objects/xp_rules.dart';

/// Откатывает последний ответ по слову (ADR-010).
///
/// Удаляет последнюю запись журнала, восстанавливает состояние карточки из её
/// `previousCardState` и вычитает вклад ответа из статистики дня. Если ответов
/// у слова больше нет, карточка возвращается в `newWord`.
///
/// Атомарность между тремя репозиториями — Phase 5 (BL-34): сейчас это
/// последовательные вызовы.
final class UndoLastReview {
  /// Создаёт use case.
  const UndoLastReview({
    required ProgressRepository progress,
    required ReviewLogRepository reviewLog,
    required StatsRepository stats,
  }) : _progress = progress,
       _reviewLog = reviewLog,
       _stats = stats;

  final ProgressRepository _progress;
  final ReviewLogRepository _reviewLog;
  final StatsRepository _stats;

  /// Откатывает последний ответ для [wordId].
  ///
  /// Возвращает `false`, если откатывать нечего.
  Future<bool> call(WordId wordId) async {
    final logs = await _reviewLog.getByWordId(wordId);
    if (logs.isEmpty) {
      return false;
    }
    final last = logs.last;
    final progress = await _progress.getByWordId(wordId);

    await _reviewLog.delete(last.id);
    if (progress == null) {
      return false;
    }

    final remaining = logs.length - 1;
    await _progress.upsert(
      progress.copyWith(
        cardState: last.previousCardState,
        lastReviewedAt: remaining == 0 ? null : progress.lastReviewedAt,
        status: remaining == 0 ? WordStatus.newWord : progress.status,
      ),
    );
    await _revertStats(last.reviewedAt, last.grade);
    return true;
  }

  /// Вычитает вклад ответа из статистики дня.
  ///
  /// `max(0, …)` защищает от отрицательных значений, если статистику правили
  /// вручную или она уже разошлась с журналом.
  Future<void> _revertStats(DateTime reviewedAt, ReviewGrade grade) async {
    final day = LocalDate.fromDateTime(reviewedAt.toLocal());
    final current = await _stats.getForDate(day);
    if (current == null) {
      return;
    }
    final correct = XpRules.isCorrect(grade) ? 1 : 0;
    await _stats.upsert(
      current.copyWith(
        reviewsCompleted: _clamp(current.reviewsCompleted - 1),
        xpGained: _clamp(current.xpGained - XpRules.forGrade(grade)),
        correctAnswers: _clamp(current.correctAnswers - correct),
      ),
    );
  }

  int _clamp(int value) => value < 0 ? 0 : value;
}
