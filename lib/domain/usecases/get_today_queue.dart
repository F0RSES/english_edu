import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Собирает очередь на сегодня из прогресса и настроек.
///
/// Порядок due — по dueAt ascending, обрезан dailyReviewLimit.
/// Порядок newWords — по firstSeenAt ascending, обрезан dailyNewLimit.
final class GetTodayQueue {
  /// Creates the use case.
  const GetTodayQueue({
    required WordRepository words,
    required ProgressRepository progress,
    required SettingsRepository settings,
    required DateTime Function() clock,
  }) : _words = words,
       _progress = progress,
       _settings = settings,
       _clock = clock;

  final WordRepository _words;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Returns the queue for the current day.
  ///
  /// Порядок due — по dueAt ascending, обрезан dailyReviewLimit. Порядок
  /// newWords — по firstSeenAt ascending, обрезан dailyNewLimit.
  ///
  /// Слова со статусом newWord исключены из due (они идут в newWords).
  /// Один и тот же WordId не встречается в двух списках.
  Future<TodayQueue> call() async {
    final now = _clock().toUtc();
    final settings = await _settings.get();

    final freshProgress = [...await _progress.getByStatus(WordStatus.newWord)]
      ..sort((a, b) => a.firstSeenAt.compareTo(b.firstSeenAt));
    final freshIds = {for (final item in freshProgress) item.wordId};

    final dueProgress = [...await _progress.getDueBefore(now)]
      ..removeWhere((item) => freshIds.contains(item.wordId))
      ..sort((a, b) => a.cardState.dueAt.compareTo(b.cardState.dueAt));

    final dueLimited = dueProgress
        .take(settings.dailyReviewLimit)
        .toList(growable: false);
    final freshLimited = freshProgress
        .take(settings.dailyNewLimit)
        .toList(growable: false);

    return TodayQueue(
      due: await _orderedWords(dueLimited),
      newWords: await _orderedWords(freshLimited),
    );
  }

  /// Loads words for [ordered] and restores its order.
  ///
  /// `getByIds` is free to return any order, so the result is re-mapped by id
  /// instead of being taken as is.
  Future<List<Word>> _orderedWords(List<WordProgress> ordered) async {
    if (ordered.isEmpty) {
      return const [];
    }
    final words = await _words.getByIds(ordered.map((item) => item.wordId));
    final byId = <WordId, Word>{for (final word in words) word.id: word};
    return [
      for (final item in ordered)
        if (byId[item.wordId] case final word?) word,
    ];
  }
}
