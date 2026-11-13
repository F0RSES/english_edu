import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// Помечает пропущенный день замороженной (ADR-015).
///
/// MVP: вызывается в `bootstrapApp` для вчерашнего дня, если вчера не было
/// ответов и серия не рвалась. Полная логика (streak continuity check,
/// защита от повторного списания) — Phase 5e (BL-50).
final class MarkMissedDay {
  /// Создаёт use case.
  const MarkMissedDay({required FrozenDaysRepository frozen})
    : _frozen = frozen;

  final FrozenDaysRepository _frozen;

  /// Замораживает [missedDate].
  ///
  /// Дата — ключ, поэтому повторный вызов идемпотентен.
  Future<void> call(LocalDate missedDate) =>
      _frozen.add(missedDate, reason: _missedDayReason);

  /// Причина заморозки, которую ставит приложение при пропуске.
  static const String _missedDayReason = 'missedDay';
}
