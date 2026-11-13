import 'package:english_edu/domain/entities/chat_message.dart';
import 'package:english_edu/domain/value_objects/chat_role.dart';
import 'package:test/test.dart';

final _utc = DateTime.utc(2026, 11, 13, 12);

ChatMessage message({
  int id = 1,
  ChatRole role = ChatRole.user,
  String content = 'Привет',
  DateTime? createdAtUtc,
}) => ChatMessage(
  id: id,
  role: role,
  content: content,
  createdAtUtc: createdAtUtc ?? _utc,
);

void main() {
  test('should_be_equal_when_all_fields_match', () {
    expect(message(), message());
    expect(message().hashCode, message().hashCode);
  });

  test('should_differ_when_any_field_differs', () {
    expect(message(), isNot(message(id: 2)));
    expect(message(), isNot(message(role: ChatRole.assistant)));
    expect(message(), isNot(message(content: 'Другое')));
    expect(
      message(),
      isNot(message(createdAtUtc: DateTime.utc(2026, 11, 13, 13))),
    );
  });

  test('should_throw_argument_error_when_created_at_is_not_utc', () {
    expect(
      () => message(createdAtUtc: DateTime(2026, 11, 13, 12)),
      throwsArgumentError,
    );
  });

  test('should_keep_utc_timestamp', () {
    expect(message().createdAtUtc.isUtc, isTrue);
  });

  test('should_have_user_and_assistant_roles', () {
    expect(ChatRole.values, [ChatRole.user, ChatRole.assistant]);
    expect(ChatRole.user.name, 'user');
    expect(ChatRole.assistant.name, 'assistant');
  });

  test('should_not_include_content_in_toString', () {
    expect(message().toString(), isNot(contains('Привет')));
  });
}
