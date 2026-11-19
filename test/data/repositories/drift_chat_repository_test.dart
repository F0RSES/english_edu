import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_chat_repository.dart';
import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 19, 12);

ChatMessage message({
  required int sessionId,
  required String content,
  ChatRole role = ChatRole.user,
  DateTime? createdAtUtc,
}) => ChatMessage(
  id: 0,
  sessionId: sessionId,
  role: role,
  content: content,
  createdAtUtc: createdAtUtc ?? _now,
);

void main() {
  late AppDatabase db;
  late DriftChatRepository repo;
  late int sessionA;
  late int sessionB;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftChatRepository(db);
    sessionA = await db
        .into(db.chatSessions)
        .insert(
          ChatSessionsCompanion.insert(
            title: 'A',
            createdAtUtc: _now.millisecondsSinceEpoch,
            updatedAtUtc: _now.millisecondsSinceEpoch,
          ),
        );
    sessionB = await db
        .into(db.chatSessions)
        .insert(
          ChatSessionsCompanion.insert(
            title: 'B',
            createdAtUtc: _now.millisecondsSinceEpoch,
            updatedAtUtc: _now.millisecondsSinceEpoch,
          ),
        );
  });
  tearDown(() => db.close());

  test('should_assign_id_and_keep_session_when_appended', () async {
    await repo.append(message(sessionId: sessionA, content: 'Привет'));

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.id, greaterThan(0));
    expect(all.single.sessionId, sessionA);
    expect(all.single.content, 'Привет');
  });

  test('should_return_only_session_messages_when_get_by_session', () async {
    await repo.append(message(sessionId: sessionA, content: 'a1'));
    await repo.append(message(sessionId: sessionB, content: 'b1'));
    await repo.append(
      message(
        sessionId: sessionA,
        content: 'a2',
        createdAtUtc: _now.add(const Duration(minutes: 1)),
      ),
    );

    final a = await repo.getBySession(sessionA);

    expect(a.map((m) => m.content), ['a1', 'a2']);
    expect((await repo.getBySession(sessionB)).single.content, 'b1');
    expect(await repo.getAll(), hasLength(3));
  });

  test('should_return_last_n_of_session_when_get_last_n', () async {
    for (var i = 1; i <= 5; i++) {
      await repo.append(
        message(
          sessionId: sessionA,
          content: 'a$i',
          createdAtUtc: _now.add(Duration(minutes: i)),
        ),
      );
    }
    await repo.append(message(sessionId: sessionB, content: 'b1'));

    final last = await repo.getLastN(2, sessionId: sessionA);

    // Хронологический порядок: от старых к новым, только своя сессия.
    expect(last.map((m) => m.content), ['a4', 'a5']);
  });

  test('should_throw_when_n_not_positive_on_get_last_n', () async {
    await expectLater(
      repo.getLastN(0, sessionId: sessionA),
      throwsArgumentError,
    );
  });

  test('should_clear_only_session_when_cleared', () async {
    await repo.append(message(sessionId: sessionA, content: 'a1'));
    await repo.append(message(sessionId: sessionB, content: 'b1'));

    await repo.clear(sessionA);

    expect(await repo.getBySession(sessionA), isEmpty);
    expect((await repo.getAll()).single.content, 'b1');
  });

  test('should_throw_when_created_at_not_utc_on_append', () async {
    // Entity валидирует UTC раньше репозитория: ошибка бросается уже
    // при конструировании сообщения.
    await expectLater(
      () => repo.append(
        ChatMessage(
          id: 0,
          sessionId: sessionA,
          role: ChatRole.user,
          content: 'Привет',
          createdAtUtc: DateTime(2026, 11, 19, 12),
        ),
      ),
      throwsArgumentError,
    );
  });
}
