import 'package:english_edu/domain/value_objects/local_date.dart';

/// Хранилище заморозок серии (ADR-015).
///
/// Домен не различает «заработано» и «израсходовано»: заморозка — это запись
/// на конкретную дату, а баланс выводится из `StreakRule.frozenEarnedFor`
/// минус размер множества.
abstract interface class FrozenDaysRepository {
  /// Возвращает даты, покрытые заморозкой.
  Future<Set<LocalDate>> getAll();

  /// Помечает [date] замороженной.
  ///
  /// Повторный вызов на ту же дату не создаёт вторую запись: дата — ключ.
  /// [reason] — `missedDay` сейчас, `manual` зарезервирован для Phase 5e.
  Future<void> add(LocalDate date, {required String reason});

  /// Заменяет все заморозки [dates].
  ///
  /// Нужен импорту состояния; сейчас в payload схемы v1 заморозки не входят.
  Future<void> replaceAll(Iterable<LocalDate> dates);
}
