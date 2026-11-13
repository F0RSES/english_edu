import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';

/// Сбрасывает прогресс обучения, оставляя словарь и настройки (ADR-013).
///
/// Удаляются только производные от ответов данные: `WordProgress`,
/// `ReviewLog`, `DailyStats`. Порядок важен — сначала прогресс (на него
/// ссылаются внешние ключи), затем логи, затем статистика: обратный порядок
/// оставил бы логи на удалённые карточки.
final class ResetProgress {
  /// Creates the use case.
  const ResetProgress({
    required ProgressRepository progress,
    required ReviewLogRepository reviewLog,
    required StatsRepository stats,
  }) : _progress = progress,
       _reviewLog = reviewLog,
       _stats = stats;

  final ProgressRepository _progress;
  final ReviewLogRepository _reviewLog;
  final StatsRepository _stats;

  /// Очищает прогресс, логи и статистику.
  Future<void> call() async {
    await _progress.replaceAll(const []);
    await _reviewLog.replaceAll(const []);
    await _stats.replaceAll(const []);
  }
}
