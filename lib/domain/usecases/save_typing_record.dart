import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';

/// Считает метрики заезда и сохраняет рекорд (ADR-037).
///
/// WPM — верные слова в минуту: `correct * 60 / seconds`. Точность — доля
/// верных от всех показанных. Очки — WPM, взвешенный точностью, чтобы быстрый
/// и неаккуратный заезд не обгонял медленный и безошибочный.
final class SaveTypingRecord {
  /// Создаёт use case.
  const SaveTypingRecord({
    required TypingRecordRepository records,
    required DateTime Function() clock,
  }) : _records = records,
       _clock = clock;

  final TypingRecordRepository _records;
  final DateTime Function() _clock;

  /// Считает и сохраняет результат сессии.
  Future<TypingRecord> call({
    required int wordsCount,
    required int correctCount,
    required int durationSeconds,
  }) async {
    // Ноль секунд даёт деление на ноль: сессия короче секунды считается
    // секундой — иначе WPM был бы бесконечным.
    final seconds = durationSeconds <= 0 ? 1 : durationSeconds;
    final wpm = (correctCount * 60 / seconds).round();
    final accuracy = wordsCount <= 0
        ? 0
        : (correctCount * 100 / wordsCount).round();

    return await _records.save(
      TypingRecord(
        id: 0,
        wordsCount: wordsCount,
        correctCount: correctCount,
        durationSeconds: seconds,
        wpm: wpm,
        accuracyPercent: accuracy,
        score: (wpm * accuracy) ~/ 100,
        createdAtUtc: _clock().toUtc(),
      ),
    );
  }
}
