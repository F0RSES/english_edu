import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Хранилище ежедневных заданий (Phase 15b, ADR-030).
///
/// Одна запись на локальный день: карточка главного экрана показывает задание
/// сегодняшнего дня, а вчерашнее остаётся в истории.
abstract interface class DailyChallengeRepository {
  /// Возвращает задание на [date] или null, если день ещё не начат.
  Future<DailyChallenge?> getForDate(LocalDate date);

  /// Сохраняет [challenge]; повторная запись того же дня заменяет предыдущую.
  ///
  /// Время в [challenge] должно быть в UTC: локальное время в БД не хранится.
  Future<void> save(DailyChallenge challenge);
}
