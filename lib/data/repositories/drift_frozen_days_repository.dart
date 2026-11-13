import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// `FrozenDaysRepository` поверх Drift (ADR-015).
///
/// Время расхода берётся из внедрённых часов: репозиторий не должен читать
/// системное время, иначе тесты зависят от даты запуска.
final class DriftFrozenDaysRepository implements FrozenDaysRepository {
  /// Создаёт репозиторий поверх базы и внедрённых часов.
  const DriftFrozenDaysRepository(
    this._db, {
    required DateTime Function() clock,
  }) : _clock = clock;

  final AppDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<Set<LocalDate>> getAll() async {
    final rows = await _db.select(_db.frozenDays).get();
    return {for (final row in rows) LocalDate(row.dateEpochDays)};
  }

  @override
  Future<void> add(LocalDate date, {required String reason}) async {
    await _db
        .into(_db.frozenDays)
        .insertOnConflictUpdate(
          FrozenDaysCompanion.insert(
            dateEpochDays: Value(date.daysSinceEpoch),
            consumedAtUtc: _nowMs,
            reason: reason,
          ),
        );
  }

  @override
  Future<void> replaceAll(Iterable<LocalDate> dates) async {
    final nowMs = _nowMs;
    await _db.transaction(() async {
      await _db.delete(_db.frozenDays).go();
      for (final date in dates) {
        await _db
            .into(_db.frozenDays)
            .insert(
              FrozenDaysCompanion.insert(
                dateEpochDays: Value(date.daysSinceEpoch),
                consumedAtUtc: nowMs,
                // Причина при восстановлении снимка неизвестна; `missedDay` —
                // единственный сценарий, который пишет приложение.
                reason: 'missedDay',
              ),
            );
      }
    });
  }

  /// Текущий момент в миллисекундах UTC — время расхода заморозки.
  int get _nowMs => _clock().toUtc().millisecondsSinceEpoch;
}
