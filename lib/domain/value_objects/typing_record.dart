import 'package:meta/meta.dart';

DateTime _requireUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'must be UTC');
  }
  return value;
}

/// Результат одной сессии «Typing Speed» (ADR-037).
///
/// Не `const`: `createdAtUtc` проверяется на UTC в runtime (`assert` в release
/// вырезается).
@immutable
final class TypingRecord {
  /// Создаёт запись; [createdAtUtc] должен быть в UTC.
  TypingRecord({
    required this.id,
    required this.wordsCount,
    required this.correctCount,
    required this.durationSeconds,
    required this.wpm,
    required this.accuracyPercent,
    required this.score,
    required DateTime createdAtUtc,
  }) : createdAtUtc = _requireUtc(createdAtUtc, 'createdAtUtc');

  /// Идентификатор в БД; 0 — запись ещё не сохранена.
  final int id;

  /// Сколько слов было в сессии.
  final int wordsCount;

  /// Сколько набрано верно.
  final int correctCount;

  /// Длительность в секундах.
  final int durationSeconds;

  /// Слов в минуту.
  final int wpm;

  /// Точность в процентах.
  final int accuracyPercent;

  /// Итоговые очки.
  final int score;

  /// Момент завершения, UTC.
  final DateTime createdAtUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingRecord &&
          id == other.id &&
          wordsCount == other.wordsCount &&
          correctCount == other.correctCount &&
          durationSeconds == other.durationSeconds &&
          wpm == other.wpm &&
          accuracyPercent == other.accuracyPercent &&
          score == other.score &&
          createdAtUtc == other.createdAtUtc;

  @override
  int get hashCode => Object.hash(
    id,
    wordsCount,
    correctCount,
    durationSeconds,
    wpm,
    accuracyPercent,
    score,
    createdAtUtc,
  );

  @override
  String toString() =>
      'TypingRecord($wpm wpm, $accuracyPercent%, score: $score)';
}
