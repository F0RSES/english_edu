import 'package:english_edu/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'NoOpNotificationService completes every call without throwing',
    () async {
      const service = NoOpNotificationService();

      await expectLater(service.requestPermission(), completes);
      await expectLater(
        service.scheduleDailyReminder(hour: 9, minute: 0),
        completes,
      );
      await expectLater(service.cancelAll(), completes);
    },
  );

  test('NoOpNotificationService is a NotificationService', () {
    const NotificationService service = NoOpNotificationService();
    expect(service, isA<NoOpNotificationService>());
  });
}
