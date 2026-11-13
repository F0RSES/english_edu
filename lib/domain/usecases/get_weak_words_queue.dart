import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/today_queue.dart';

/// Очередь «проблемных» слов для отдельного повторения (ADR-026).
///
/// Проблемное слово — то, которое уже проваливали (`lapses > 0`) или чей
/// ease-фактор просел ниже 2.0. Это не замена SRS: расписание по-прежнему
/// считает GetTodayQueue, а здесь пользователь сам просит «добить» слабые
/// карточки, не дожидаясь их `dueAt`.
///
/// Порядок: сначала больше провалов, при равенстве — меньше ease. Так самое
/// проблемное слово показывается первым, а не самое «свежее» по дате.
///
/// `newWords` всегда пуст: это режим повторения, новых слов он не вводит.
/// Повторяются только слова выбранного уровня (Phase 27a).
final class GetWeakWordsQueue {
  /// Создаёт use case.
  const GetWeakWordsQueue({
    required WordRepository words,
    required ProgressRepository progress,
    required SettingsRepository settings,
  }) : _words = words,
       _progress = progress,
       _settings = settings;

  final WordRepository _words;
  final ProgressRepository _progress;
  final SettingsRepository _settings;

  /// Возвращает проблемные слова в порядке приоритета.
  Future<TodayQueue> call() async {
    final level = (await _settings.get()).preferredLevel;
    final allWords = await _words.getByLevel(level);
    final allProgress = await _progress.getAll();
    final wordById = {for (final word in allWords) word.id: word};

    final weakProgress =
        <WordProgress>[
          for (final item in allProgress)
            if (_isWeak(item)) item,
        ]..sort((left, right) {
          final byLapses = right.cardState.lapses.compareTo(
            left.cardState.lapses,
          );
          if (byLapses != 0) {
            return byLapses;
          }
          return left.cardState.ease.compareTo(right.cardState.ease);
        });

    return TodayQueue(
      // Прогресс без слова (слово удалили) пропускается: показать нечего.
      due: [
        for (final item in weakProgress)
          if (wordById[item.wordId] case final word?) word,
      ],
      newWords: const [],
    );
  }

  /// Проваливали хотя бы раз или ease ниже 2.0.
  ///
  /// Порог 2.0, а не 2.5 (стартовый ease): 2.5 — норма для новой карточки,
  /// поэтому «ниже 2.0» ловит именно просевшие, а не все подряд.
  static bool _isWeak(WordProgress progress) =>
      progress.cardState.lapses > 0 || progress.cardState.ease < 2.0;
}
