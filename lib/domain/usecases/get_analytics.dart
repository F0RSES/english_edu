import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/analytics.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Собирает сводку для экрана аналитики (ADR-021).
///
/// Только чтение: словарь, прогресс и дневная статистика. Слова без записи в
/// `WordProgress` считаются новыми — та же семантика, что в `GetTodayQueue`.
final class GetAnalytics {
  /// Создаёт use case.
  const GetAnalytics({
    required WordRepository words,
    required ProgressRepository progress,
    required StatsRepository stats,
    required DateTime Function() clock,
  }) : _words = words,
       _progress = progress,
       _stats = stats,
       _clock = clock;

  /// Окно графика: 7 дней, включая сегодня.
  static const int windowDays = 7;

  /// Сколько слов попадает в «трудные».
  static const int hardWordsLimit = 5;

  final WordRepository _words;
  final ProgressRepository _progress;
  final StatsRepository _stats;
  final DateTime Function() _clock;

  /// Считает сводку на текущий локальный день.
  Future<Analytics> call() async {
    final today = LocalDate.fromDateTime(_clock().toLocal());
    final allWords = await _words.getAll();
    final allProgress = await _progress.getAll();
    final last7Days = await _lastSevenDays(today);

    // Прогресс мог остаться от удалённых слов: считаем только живые.
    final wordById = {for (final word in allWords) word.id: word};
    final liveProgress = [
      for (final item in allProgress)
        if (wordById.containsKey(item.wordId)) item,
    ];

    // Нет записи в прогрессе — слово новое (та же семантика, что в очереди).
    final statusByWordId = {
      for (final item in liveProgress) item.wordId: item.status,
    };
    var mastered = 0;
    var learning = 0;
    var fresh = 0;
    for (final word in allWords) {
      switch (statusByWordId[word.id]) {
        case WordStatus.mastered:
          mastered++;
        case WordStatus.learning:
          learning++;
        case WordStatus.newWord || null:
          fresh++;
      }
    }

    return Analytics(
      totalWords: allWords.length,
      masteredCount: mastered,
      learningCount: learning,
      newCount: fresh,
      hardestWords: _hardestWords(allWords, liveProgress),
      last7Days: last7Days,
      projectedMasteryDate: _projectMastery(
        today: today,
        total: allWords.length,
        mastered: mastered,
        progress: liveProgress,
      ),
    );
  }

  /// Ровно [windowDays] дней, oldest first.
  ///
  /// `StatsRepository.getRange` возвращает только дни с записями, поэтому окно
  /// дозаполняется `DailyStats.empty`: иначе график «съедал» бы пустые дни и
  /// показывал меньше семи столбцов.
  Future<List<DailyStats>> _lastSevenDays(LocalDate today) async {
    final from = today.addDays(-(windowDays - 1));
    final stored = await _stats.getRange(from, today);
    final byDate = {for (final item in stored) item.date: item};
    return [
      for (var offset = windowDays - 1; offset >= 0; offset--)
        byDate[today.addDays(-offset)] ??
            DailyStats.empty(today.addDays(-offset)),
    ];
  }

  /// Топ-[hardWordsLimit] слов по провалам; при равенстве — по `id`.
  List<HardWord> _hardestWords(
    List<Word> allWords,
    List<WordProgress> progress,
  ) {
    final lapsesByWordId = {
      for (final item in progress)
        if (item.cardState.lapses > 0) item.wordId: item.cardState.lapses,
    };
    final candidates =
        <HardWord>[
          for (final word in allWords)
            if (lapsesByWordId[word.id] case final lapses?)
              HardWord(word: word, lapses: lapses),
        ]..sort((a, b) {
          final byLapses = b.lapses.compareTo(a.lapses);
          return byLapses != 0
              ? byLapses
              : a.word.id.value.compareTo(b.word.id.value);
        });
    return candidates.take(hardWordsLimit).toList(growable: false);
  }

  /// Экстраполирует дату полного mastery.
  ///
  /// Скорость = `mastered / дни с первого показа слова`. Если masterеd ещё нет
  /// или осталось нечего учить, прогноз не строится (null): экстраполяция от
  /// нуля — это выдумка, а не оценка.
  LocalDate? _projectMastery({
    required LocalDate today,
    required int total,
    required int mastered,
    required List<WordProgress> progress,
  }) {
    final remaining = total - mastered;
    if (remaining <= 0 || mastered == 0 || progress.isEmpty) {
      return null;
    }
    var earliest = progress.first.firstSeenAt;
    for (final item in progress) {
      if (item.firstSeenAt.isBefore(earliest)) {
        earliest = item.firstSeenAt;
      }
    }
    final startedOn = LocalDate.fromDateTime(earliest.toLocal());
    final elapsedDays = today.daysSinceEpoch - startedOn.daysSinceEpoch;
    // Сегодняшний старт: делим на 1, иначе получим бесконечность.
    final days = elapsedDays < 1 ? 1 : elapsedDays;
    final neededDays = (remaining * days / mastered).ceil();
    return today.addDays(neededDays);
  }
}
