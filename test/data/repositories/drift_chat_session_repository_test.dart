import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_chat_session_repository.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 19, 12);

void main() {
  late AppDatabase db;
  late DriftChatSessionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftChatSessionRepository(db);
  });
  tearDown(() => db.close());

  test('should_assign_id_and_timestamps_when_session_created', () async {
    final created = await repo.create(title: 'Новый чат', createdAtUtc: _now);

    expect(created.id, greaterThan(0));
    expect(created.title, 'Новый чат');
    expect(created.isPinned, isFalse);
    expect(created.createdAtUtc, _now);
    expect(created.updatedAtUtc, _now);
    expect(await repo.getAll(), [created]);
  });

  test('should_trim_title_when_created_with_spaces', () async {
    final created = await repo.create(title: '  Чат  ', createdAtUtc: _now);
    expect(created.title, 'Чат');
  });

  test('should_sort_pinned_first_then_updated_desc_when_get_all', () async {
    final old = await repo.create(title: 'Старый', createdAtUtc: _now);
    final fresh = await repo.create(
      title: 'Свежий',
      createdAtUtc: _now.add(const Duration(hours: 1)),
    );
    final pinnedOld = await repo.create(
      title: 'Закреплённый старый',
      createdAtUtc: _now.subtract(const Duration(days: 30)),
    );
    await repo.togglePin(pinnedOld.id);

    final all = await repo.getAll();

    expect(all.map((s) => s.id), [pinnedOld.id, fresh.id, old.id]);
  });

  test('should_return_most_recent_by_updated_when_get_most_recent', () async {
    final pinnedOld = await repo.create(
      title: 'Закреплённый',
      createdAtUtc: _now.subtract(const Duration(days: 30)),
    );
    await repo.togglePin(pinnedOld.id);
    final fresh = await repo.create(title: 'Свежий', createdAtUtc: _now);

    // Закрепление не влияет: восстанавливается последний активный диалог.
    expect((await repo.getMostRecent())?.id, fresh.id);
  });

  test('should_return_null_when_no_sessions_for_get_most_recent', () async {
    expect(await repo.getMostRecent(), isNull);
  });

  test('should_cascade_messages_when_session_deleted', () async {
    final session = await repo.create(title: 'Чат', createdAtUtc: _now);
    await db
        .into(db.chatMessages)
        .insert(
          ChatMessagesCompanion.insert(
            sessionId: session.id,
            role: ChatRole.user.name,
            content: 'Привет',
            createdAtUtc: _now.millisecondsSinceEpoch,
          ),
        );

    await repo.delete(session.id);

    expect(await repo.getAll(), isEmpty);
    expect(await db.select(db.chatMessages).get(), isEmpty);
  });

  test('should_keep_updated_at_when_renamed', () async {
    final session = await repo.create(title: 'Старое имя', createdAtUtc: _now);
    final later = _now.add(const Duration(hours: 2));
    await repo.touch(session.id, later);

    await repo.rename(session.id, 'Новое имя');

    final updated = (await repo.getAll()).single;
    expect(updated.title, 'Новое имя');
    expect(updated.updatedAtUtc, later);
  });

  test('should_toggle_pin_without_touching_updated_at_when_toggled', () async {
    final session = await repo.create(title: 'Чат', createdAtUtc: _now);

    await repo.togglePin(session.id);
    expect((await repo.getAll()).single.isPinned, isTrue);
    expect((await repo.getAll()).single.updatedAtUtc, _now);

    await repo.togglePin(session.id);
    expect((await repo.getAll()).single.isPinned, isFalse);
    expect((await repo.getAll()).single.updatedAtUtc, _now);
  });

  test('should_update_updated_at_when_touched', () async {
    final session = await repo.create(title: 'Чат', createdAtUtc: _now);
    final later = _now.add(const Duration(minutes: 5));

    await repo.touch(session.id, later);

    expect((await repo.getAll()).single.updatedAtUtc, later);
    expect((await repo.getAll()).single.createdAtUtc, _now);
  });

  test('should_throw_when_title_empty_on_create', () async {
    await expectLater(
      repo.create(title: '   ', createdAtUtc: _now),
      throwsArgumentError,
    );
  });

  test('should_throw_when_title_empty_on_rename', () async {
    final session = await repo.create(title: 'Чат', createdAtUtc: _now);
    await expectLater(repo.rename(session.id, '  '), throwsArgumentError);
  });

  test('should_throw_when_not_utc_on_create', () async {
    await expectLater(
      repo.create(title: 'Чат', createdAtUtc: DateTime(2026, 11, 19, 12)),
      throwsArgumentError,
    );
  });

  test('should_throw_when_not_utc_on_touch', () async {
    final session = await repo.create(title: 'Чат', createdAtUtc: _now);
    await expectLater(
      repo.touch(session.id, DateTime(2026, 11, 19, 13)),
      throwsArgumentError,
    );
  });

  test('should_ignore_unknown_id_when_renamed_pinned_or_touched', () async {
    await repo.rename(999, 'Имя');
    await repo.togglePin(999);
    await repo.touch(999, _now);
    expect(await repo.getAll(), isEmpty);
  });
}
