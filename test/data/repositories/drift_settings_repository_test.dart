import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_settings_repository.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2024, 5, 15, 12);

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftSettingsRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('returns defaults when nothing is stored', () async {
    expect(await repo.get(), UserSettings.defaults());
    expect(await db.select(db.userSettingsTable).get(), isEmpty);
  });

  test('saves and reads settings back', () async {
    final settings = UserSettings.defaults()
        .copyWith(dailyNewLimit: 4, remindersEnabled: true, reminderHour: 20);

    await repo.save(settings);

    expect(await repo.get(), settings);
  });

  test('saves twice without creating a second row', () async {
    await repo.save(UserSettings.defaults());
    await repo.save(UserSettings.defaults().copyWith(dailyReviewLimit: 12));

    final rows = await db.select(db.userSettingsTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.updatedAtUtc, now.millisecondsSinceEpoch);
    expect((await repo.get()).dailyReviewLimit, 12);
  });

  test('keeps a fractional ttsSpeed', () async {
    final settings = UserSettings.defaults().copyWith(ttsSpeed: 0.55);

    await repo.save(settings);

    expect((await repo.get()).ttsSpeed, 0.55);
  });
}
