import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/smart_review_item.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Вес одного провала: один `again` важнее одного дня давности в 10 раз.
const double _lapsesWeight = 10;

/// Вес отклонения ease от стартового значения.
const double _easeWeight = 20;

/// Нормальный ease новой карточки; ниже — просевший.
const double _baseEase = 2.5;

/// С какого возраста карточка считается «давно не виденной».
const int _staleThresholdDays = 7;

/// Ранжированная очередь повторения (ADR-033).
///
/// Отличие от `GetWeakWordsQueue` (ADR-026): там фильтр «проваливал или ease
/// просел», здесь — оценка важности, где давность тоже двигает слово вверх.
/// Слово с чистым `lapses = 0`, но не виденное месяц, обгоняет слово,
/// проваленное вчера.
///
/// Только чтение: ничего не пишет в БД. `newWords` вне scope — для новых слов
/// есть расписание SRS. `mastered` исключается: выученное слово не нужно
/// поднимать вручную. В очередь попадают только слова выбранного уровня
/// (Phase 27a).
final class GetSmartReviewQueue {
  /// Создаёт use case.
  const GetSmartReviewQueue({
    required WordRepository words,
    required ProgressRepository progress,
    required SettingsRepository settings,
    required DateTime Function() clock,
    this.maxItems = 20,
  }) : _words = words,
       _progress = progress,
       _settings = settings,
       _clock = clock;

  final WordRepository _words;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final DateTime Function() _clock;

  /// Сколько элементов максимум вернуть.
  ///
  /// Ограничение нужно, чтобы сессия не превращалась в бесконечную: очередь
  /// строится из всей базы, а не из дневного лимита.
  final int maxItems;

  /// Возвращает до [maxItems] слов, отсортированных по убыванию приоритета.
  Future<List<SmartReviewItem>> call() async {
    final now = _clock().toUtc();
    final allProgress = await _progress.getAll();
    if (allProgress.isEmpty) {
      return const [];
    }

    final level = (await _settings.get()).preferredLevel;
    final allWords = await _words.getByLevel(level);
    final wordById = {for (final word in allWords) word.id: word};

    final items = <SmartReviewItem>[];
    for (final progress in allProgress) {
      final word = wordById[progress.wordId];
      // Прогресс без слова — осиротевшая строка (слово удалили в обход
      // каскада): показывать нечего.
      if (word == null) {
        continue;
      }
      if (progress.status == WordStatus.mastered) {
        continue;
      }

      final scored = _score(progress, now);
      if (scored == null) {
        continue;
      }
      items.add(
        SmartReviewItem(
          word: word,
          progress: progress,
          priorityScore: scored.score,
          reason: scored.reason,
        ),
      );
    }

    // Сортировка по убыванию: самое важное слово показывается первым.
    items.sort(
      (left, right) => right.priorityScore.compareTo(left.priorityScore),
    );
    return items.take(maxItems).toList();
  }

  /// Считает score и причину; null — слово сегодня не приоритетно.
  ({double score, String reason})? _score(WordProgress progress, DateTime now) {
    var score = 0.0;
    final reasons = <String>[];

    // 1. Трудность: каждый провал весит больше, чем день давности.
    final lapses = progress.cardState.lapses;
    if (lapses > 0) {
      score += lapses * _lapsesWeight;
      reasons.add('Трудное ($lapses провалов)');
    }

    // 2. Давность: слово выпало из оборота.
    final days = _daysSinceReview(progress, now);
    if (days > _staleThresholdDays) {
      score += days.toDouble();
      reasons.add('Не видел $days дней');
    }

    // 3. Ease ниже нормы — слово даётся тяжелее, чем должно.
    final ease = progress.cardState.ease;
    if (ease < _baseEase) {
      score += (_baseEase - ease) * _easeWeight;
    }

    if (score <= 0) {
      return null;
    }
    return (
      score: score,
      // Своей причины у просевшего ease нет: это «остаточный» фактор, и
      // приписывать ему «трудное» было бы неправдой.
      reason: reasons.isEmpty ? 'Низкий ease' : reasons.first,
    );
  }

  /// Дней с последнего показа: ответа нет — считаем от первого появления.
  int _daysSinceReview(WordProgress progress, DateTime now) {
    final reference = progress.lastReviewedAt ?? progress.firstSeenAt;
    return now.difference(reference).inDays;
  }
}
