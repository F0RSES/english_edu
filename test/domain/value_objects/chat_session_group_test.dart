import 'package:english_edu/domain/value_objects/chat_session_group.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:test/test.dart';

// Локальные моменты строятся от локального «сегодня»: тест не зависит
// от TZ хоста (toUtc/toLocal возвращают тот же локальный день).
final _todayLocal = DateTime(2026, 11, 19, 12);
final _today = LocalDate.fromDateTime(_todayLocal);

ChatSessionGroup groupOf(DateTime updatedAtLocal, {bool isPinned = false}) =>
    ChatSessionGroup.of(
      isPinned: isPinned,
      updatedAtUtc: updatedAtLocal.toUtc(),
      today: _today,
    );

void main() {
  test('should_group_pinned_when_session_is_pinned', () {
    expect(
      groupOf(DateTime(2026, 10), isPinned: true),
      ChatSessionGroup.pinned,
    );
    expect(groupOf(_todayLocal, isPinned: true), ChatSessionGroup.pinned);
  });

  test('should_group_today_when_updated_this_local_day', () {
    expect(groupOf(DateTime(2026, 11, 19, 0, 5)), ChatSessionGroup.today);
    expect(groupOf(DateTime(2026, 11, 19, 23, 59)), ChatSessionGroup.today);
  });

  test('should_group_yesterday_when_updated_previous_local_day', () {
    expect(groupOf(DateTime(2026, 11, 18, 23, 59)), ChatSessionGroup.yesterday);
    expect(groupOf(DateTime(2026, 11, 18, 0, 1)), ChatSessionGroup.yesterday);
  });

  test('should_group_last_seven_days_when_updated_two_to_seven_days_ago', () {
    expect(groupOf(DateTime(2026, 11, 17, 12)), ChatSessionGroup.lastSevenDays);
    expect(groupOf(DateTime(2026, 11, 12, 12)), ChatSessionGroup.lastSevenDays);
  });

  test('should_group_older_when_updated_more_than_seven_days_ago', () {
    expect(groupOf(DateTime(2026, 11, 11, 12)), ChatSessionGroup.older);
    expect(groupOf(DateTime(2025)), ChatSessionGroup.older);
  });

  test('should_group_today_when_updated_in_the_future', () {
    expect(groupOf(DateTime(2026, 11, 20, 12)), ChatSessionGroup.today);
  });
}
