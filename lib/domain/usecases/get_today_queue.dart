import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Собирает очередь на сегодня, сопоставляя словарь с прогрессом.
///
/// Слово без записи в `WordProgress` — это новое слово: seed и добавление через
/// `AddWordDialog` создают только строку словаря. Поэтому очередь строится от
/// **списка слов**, а не от прогресса: иначе новые слова не попадают в сессию
/// и экран показывает «на сегодня всё» при непустом словаре.
///
/// Порядок: due — по `dueAt` возрастанию; newWords — по `firstSeenAt`
/// возрастанию, а слова без прогресса идут после уже введённых, по `id`.
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
  /// Один и тот же `WordId` не встречается в двух списках: слова со статусом
  /// `newWord` (и без прогресса) идут только в `TodayQueue.newWords`, а due —
  /// это прогресс с наступившим `dueAt` и статусом `learning`/`mastered`.
  Future<TodayQueue> call() async {
    final now = _clock().toUtc();
    final settings = await _settings.get();

    final allWords = await _words.getAll();
    final allProgress = await _progress.getAll();
    final wordById = {for (final word in allWords) word.id: word};
    final progressByWordId = {
      for (final item in allProgress) item.wordId: item,
    };

    return TodayQueue(
      due: _dueWords(
        allProgress: allProgress,
        wordById: wordById,
        now: now,
        limit: settings.dailyReviewLimit,
      ),
      newWords: _newWords(
        allWords: allWords,
        progressByWordId: progressByWordId,
        limit: settings.dailyNewLimit,
      ),
    );
  }

  /// Слова к повторению: `dueAt` уже наступил, статус — не `newWord`.
  ///
  /// Порядок берётся от прогресса (`dueAt` asc), а не от порядка слов: так
  /// самые просроченные карточки идут первыми. Прогресс без слова (слово
  /// удалили) пропускается.
  List<Word> _dueWords({
    required List<WordProgress> allProgress,
    required Map<WordId, Word> wordById,
    required DateTime now,
    required int limit,
  }) {
    if (limit == 0) {
      return const [];
    }
    final dueProgress = [
      for (final item in allProgress)
        if (item.status != WordStatus.newWord &&
            !item.cardState.dueAt.isAfter(now))
          item,
    ]..sort((a, b) => a.cardState.dueAt.compareTo(b.cardState.dueAt));

    final result = <Word>[];
    for (final item in dueProgress) {
      if (result.length >= limit) {
        break;
      }
      if (wordById[item.wordId] case final word?) {
        result.add(word);
      }
    }
    return result;
  }

  /// Новые слова: нет прогресса или статус `newWord`.
  ///
  /// Сначала те, кого уже показывали (`firstSeenAt` asc), затем ещё не
  /// введённые — по `id`, чтобы порядок не зависел от порядка строк в БД.
  List<Word> _newWords({
    required List<Word> allWords,
    required Map<WordId, WordProgress> progressByWordId,
    required int limit,
  }) {
    if (limit == 0) {
      return const [];
    }
    final candidates =
        <({Word word, DateTime? firstSeenAt})>[
          for (final word in allWords)
            if (_isNewWord(word, progressByWordId))
              (word: word, firstSeenAt: progressByWordId[word.id]?.firstSeenAt),
        ]..sort((a, b) {
          final aSeen = a.firstSeenAt;
          final bSeen = b.firstSeenAt;
          if (aSeen != null && bSeen != null) {
            final bySeenAt = aSeen.compareTo(bSeen);
            if (bySeenAt != 0) {
              return bySeenAt;
            }
          } else if (aSeen != null) {
            return -1;
          } else if (bSeen != null) {
            return 1;
          }
          return a.word.id.value.compareTo(b.word.id.value);
        });

    return [for (final candidate in candidates.take(limit)) candidate.word];
  }

  /// Считается ли [word] новым для пользователя.
  bool _isNewWord(Word word, Map<WordId, WordProgress> progressByWordId) {
    final progress = progressByWordId[word.id];
    return progress == null || progress.status == WordStatus.newWord;
  }
}
