import 'package:english_edu/domain/value_objects/local_date.dart';

/// Группа сессии в списке истории чата (Phase 42, ADR-046).
///
/// Границы определяются локальными календарными днями: смена дня —
/// локальная полночь (конвенция проекта для streak).
enum ChatSessionGroup {
  /// Закреплённые: всегда сверху, независимо от даты.
  pinned,

  /// Обновлена сегодня (локальный день).
  today,

  /// Обновлена вчера.
  yesterday,

  /// Обновлена 2–7 локальных дней назад.
  lastSevenDays,

  /// Обновлена более 7 локальных дней назад.
  older;

  /// Группа сессии с признаком [isPinned] и моментом [updatedAtUtc],
  /// если сегодняшний локальный день — [today].
  static ChatSessionGroup of({
    required bool isPinned,
    required DateTime updatedAtUtc,
    required LocalDate today,
  }) {
    if (isPinned) {
      return ChatSessionGroup.pinned;
    }
    final updatedDay = LocalDate.fromDateTime(updatedAtUtc.toLocal());
    final daysAgo = today.daysSinceEpoch - updatedDay.daysSinceEpoch;
    if (daysAgo <= 0) {
      return ChatSessionGroup.today;
    }
    if (daysAgo == 1) {
      return ChatSessionGroup.yesterday;
    }
    if (daysAgo <= 7) {
      return ChatSessionGroup.lastSevenDays;
    }
    return ChatSessionGroup.older;
  }
}
