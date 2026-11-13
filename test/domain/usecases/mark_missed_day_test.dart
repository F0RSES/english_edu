import 'package:english_edu/domain/usecases/mark_missed_day.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

import 'fakes/fake_frozen_days_repository.dart';

void main() {
  test('adds a frozen day with the missedDay reason', () async {
    final frozen = FakeFrozenDaysRepository();
    const missed = LocalDate(19722);

    await MarkMissedDay(frozen: frozen).call(missed);

    expect(await frozen.getAll(), {missed});
    expect(frozen.added.single.date, missed);
    expect(frozen.added.single.reason, 'missedDay');
  });

  test('is idempotent for the same date', () async {
    final frozen = FakeFrozenDaysRepository();
    const missed = LocalDate(19722);
    final useCase = MarkMissedDay(frozen: frozen);

    await useCase.call(missed);
    await useCase.call(missed);

    expect(await frozen.getAll(), {missed});
  });
}
