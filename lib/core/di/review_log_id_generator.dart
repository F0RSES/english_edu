import 'package:english_edu/domain/value_objects/review_log_id.dart';

/// Выдаёт последовательные `ReviewLogId`, начиная со значения конструктора.
///
/// Счётчик живёт в памяти: при старте приложения он инициализируется
/// `MAX(id) + 1` из таблицы логов (ADR-009). После `replaceAll` журнала
/// счётчик нужно пересоздать — см. ADR-009, open questions.
final class NextReviewLogIdGenerator {
  /// Создаёт генератор; [start] — первый выдаваемый идентификатор.
  NextReviewLogIdGenerator(int start) : _next = start;

  int _next;

  /// Возвращает следующий идентификатор.
  ReviewLogId next() => ReviewLogId(_next++);
}
