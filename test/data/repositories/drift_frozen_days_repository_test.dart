import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_frozen_days_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2024, 5, 15, 12);

void main() {
  late AppDatabase db;
  late DriftFrozenDaysRepository frozen;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    frozen = DriftFrozenDaysRepository(db, clock: () => _now);
  });
  tearDown(() => db.close());

  test('stores a frozen day and returns it', () async {
    await frozen.add(const LocalDate(19723), reason: 'missedDay');

    expect(await frozen.getAll(), {const LocalDate(19723)});
    final row = await db.select(db.frozenDays).getSingle();
    expect(row.dateEpochDays, 19723);
    expect(row.reason, 'missedDay');
    expect(row.consumedAtUtc, _now.millisecondsSinceEpoch);
  });

  test('keeps one row per date when the same day is added twice', () async {
    await frozen.add(const LocalDate(19723), reason: 'missedDay');
    await frozen.add(const LocalDate(19723), reason: 'manual');

    final rows = await db.select(db.frozenDays).get();
    expect(rows, hasLength(1));
    // Повторная запись не должна падать: дата — первичный ключ.
    expect(rows.single.reason, 'manual');
  });

  test('replaceAll drops the previous dates', () async {
    await frozen.add(const LocalDate(19723), reason: 'missedDay');

    await frozen.replaceAll([const LocalDate(19724), const LocalDate(19725)]);

    expect(await frozen.getAll(), {
      const LocalDate(19724),
      const LocalDate(19725),
    });
  });

  test('empty replaceAll clears everything', () async {
    await frozen.add(const LocalDate(19723), reason: 'missedDay');

    await frozen.replaceAll(const []);

    expect(await frozen.getAll(), isEmpty);
  });
}
