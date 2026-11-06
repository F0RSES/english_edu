import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:meta/meta.dart';

/// Слово с наибольшим числом провалов (экран аналитики, ADR-021).
@immutable
final class HardWord {
  /// Создаёт запись; [lapses] строго больше нуля — иначе слово не «трудное».
  const HardWord({required this.word, required this.lapses})
    : assert(lapses > 0, 'lapses must be > 0');

  /// Само слово.
  final Word word;

  /// Сколько раз карточка провалена.
  final int lapses;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HardWord && word == other.word && lapses == other.lapses;

  @override
  int get hashCode => Object.hash(word, lapses);

  @override
  String toString() => 'HardWord(${word.term}, lapses: $lapses)';
}

/// Сводка прогресса для дашборда (ADR-021).
///
/// Read-only: ничего не хранит и не пишет, собирается из словаря, прогресса и
/// дневной статистики. Не `const`: списки копируются в unmodifiable.
@immutable
final class Analytics {
  /// Создаёт сводку; все счётчики неотрицательны.
  Analytics({
    required this.totalWords,
    required this.masteredCount,
    required this.learningCount,
    required this.newCount,
    required List<HardWord> hardestWords,
    required List<DailyStats> last7Days,
    this.projectedMasteryDate,
  }) : assert(totalWords >= 0, 'totalWords must be >= 0'),
       assert(masteredCount >= 0, 'masteredCount must be >= 0'),
       assert(learningCount >= 0, 'learningCount must be >= 0'),
       assert(newCount >= 0, 'newCount must be >= 0'),
       hardestWords = List.unmodifiable(hardestWords),
       last7Days = List.unmodifiable(last7Days);

  /// Сколько слов всего в словаре.
  final int totalWords;

  /// Слов со статусом `mastered`.
  final int masteredCount;

  /// Слов со статусом `learning`.
  final int learningCount;

  /// Слов без прогресса и со статусом `newWord`.
  final int newCount;

  /// До пяти самых проваливаемых слов, по убыванию `lapses`.
  final List<HardWord> hardestWords;

  /// Дневная статистика за последние 7 дней, включая сегодня, oldest first.
  final List<DailyStats> last7Days;

  /// Прогноз, когда все слова станут `mastered`; null — прогноз невозможен.
  ///
  /// `LocalDate`, а не `DateTime`: это календарный день, часовой пояс в нём не
  /// участвует.
  final LocalDate? projectedMasteryDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Analytics &&
          totalWords == other.totalWords &&
          masteredCount == other.masteredCount &&
          learningCount == other.learningCount &&
          newCount == other.newCount &&
          _sameItems(hardestWords, other.hardestWords) &&
          _sameItems(last7Days, other.last7Days) &&
          projectedMasteryDate == other.projectedMasteryDate;

  @override
  int get hashCode => Object.hash(
    totalWords,
    masteredCount,
    learningCount,
    newCount,
    Object.hashAll(hardestWords),
    Object.hashAll(last7Days),
    projectedMasteryDate,
  );

  @override
  String toString() =>
      'Analytics(total: $totalWords, mastered: $masteredCount, '
      'learning: $learningCount, new: $newCount, '
      'hard: ${hardestWords.length}, days: ${last7Days.length}, '
      'projected: $projectedMasteryDate)';

  static bool _sameItems<T>(List<T> left, List<T> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
