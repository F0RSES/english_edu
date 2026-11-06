import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:meta/meta.dart';

/// Элемент «умного повторения» (ADR-033).
///
/// Слово + его прогресс + приоритет + причина, которую видно в интерфейсе.
/// Чем выше [priorityScore], тем важнее показать слово сегодня; сама причина
/// хранится текстом, чтобы UI не пересчитывал правила.
@immutable
final class SmartReviewItem {
  /// Создаёт элемент очереди.
  const SmartReviewItem({
    required this.word,
    required this.progress,
    required this.priorityScore,
    required this.reason,
  });

  /// Само слово.
  final Word word;

  /// Текущее состояние изучения — источник данных для score.
  final WordProgress progress;

  /// Приоритет: больше — важнее.
  final double priorityScore;

  /// Человекочитаемая причина: «Трудное (5 провалов)», «Не видел 30 дней».
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartReviewItem &&
          word == other.word &&
          progress == other.progress &&
          priorityScore == other.priorityScore &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(word, progress, priorityScore, reason);

  @override
  String toString() =>
      'SmartReviewItem(${word.term}, score: $priorityScore, $reason)';
}
