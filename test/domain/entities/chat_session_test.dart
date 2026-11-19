import 'package:english_edu/domain/entities/chat_session.dart';
import 'package:test/test.dart';

final _utc = DateTime.utc(2026, 11, 19, 12);

ChatSession session({
  int id = 1,
  String title = 'Чат',
  bool isPinned = false,
  DateTime? createdAtUtc,
  DateTime? updatedAtUtc,
}) => ChatSession(
  id: id,
  title: title,
  isPinned: isPinned,
  createdAtUtc: createdAtUtc ?? _utc,
  updatedAtUtc: updatedAtUtc ?? _utc,
);

void main() {
  test('should_be_equal_when_all_fields_match', () {
    expect(session(), session());
    expect(session().hashCode, session().hashCode);
  });

  test('should_differ_when_any_field_differs', () {
    expect(session(), isNot(session(id: 2)));
    expect(session(), isNot(session(title: 'Другой')));
    expect(session(), isNot(session(isPinned: true)));
    expect(
      session(),
      isNot(session(createdAtUtc: DateTime.utc(2026, 11, 19, 13))),
    );
    expect(
      session(),
      isNot(session(updatedAtUtc: DateTime.utc(2026, 11, 19, 13))),
    );
  });

  test('should_throw_argument_error_when_created_at_is_not_utc', () {
    expect(
      () => session(createdAtUtc: DateTime(2026, 11, 19, 12)),
      throwsArgumentError,
    );
  });

  test('should_throw_argument_error_when_updated_at_is_not_utc', () {
    expect(
      () => session(updatedAtUtc: DateTime(2026, 11, 19, 12)),
      throwsArgumentError,
    );
  });

  test('should_keep_utc_timestamps', () {
    expect(session().createdAtUtc.isUtc, isTrue);
    expect(session().updatedAtUtc.isUtc, isTrue);
  });

  test('should_keep_short_message_as_title_when_under_limit', () {
    expect(ChatSession.titleFromMessage('Привет'), 'Привет');
    expect(ChatSession.titleFromMessage(''), '');
  });

  test('should_truncate_title_when_message_over_limit', () {
    final long = 'a' * (ChatSession.autoTitleLimit + 10);
    final title = ChatSession.titleFromMessage(long);
    expect(title, 'a' * ChatSession.autoTitleLimit);
    expect(title.length, ChatSession.autoTitleLimit);
  });

  test('should_keep_exact_limit_message_as_title_when_at_limit', () {
    final exact = 'b' * ChatSession.autoTitleLimit;
    expect(ChatSession.titleFromMessage(exact), exact);
  });

  test('should_not_include_title_in_toString', () {
    expect(
      session(title: 'Секретный чат').toString(),
      isNot(contains('Секретный чат')),
    );
  });
}
