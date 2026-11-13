import 'package:english_edu/core/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_crash_reporter.dart';

void main() {
  test(
    'NoOpCrashReporter captureException does not throw without a stack',
    () async {
      const reporter = NoOpCrashReporter();

      await expectLater(
        reporter.captureException(StateError('boom'), context: 'bootstrap'),
        completes,
      );
    },
  );

  test('NoOpCrashReporter setContext does not throw', () async {
    const reporter = NoOpCrashReporter();

    await expectLater(
      reporter.setContext('detail', <String, dynamic>{'context': 'import'}),
      completes,
    );
  });

  test(
    'FakeCrashReporter records errors with their stack and context',
    () async {
      final reporter = FakeCrashReporter();
      final error = StateError('boom');
      final stack = StackTrace.current;

      await reporter.captureException(
        error,
        stackTrace: stack,
        context: 'record_review',
      );

      expect(reporter.captured, hasLength(1));
      expect(reporter.captured.single.error, same(error));
      expect(reporter.captured.single.stackTrace, same(stack));
      expect(reporter.captured.single.context, 'record_review');
    },
  );
}
