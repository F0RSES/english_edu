import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/usecases/generate_error_task.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';
import 'package:test/test.dart';

import 'fakes/fake_settings_repository.dart';

/// Генератор, падающий первые [failures] вызовов, затем отдающий задание.
final class _FlakyGenerator implements ErrorTaskGenerator {
  _FlakyGenerator({required this.failures, required this.task});

  final int failures;
  final ErrorHunterTask task;
  int calls = 0;
  String? lastWord;
  String? lastLevel;

  @override
  Future<ErrorHunterTask> generateErrorTask(
    String word, {
    required String level,
  }) async {
    calls++;
    lastWord = word;
    lastLevel = level;
    if (calls <= failures) {
      throw StateError('ai failed');
    }
    return task;
  }
}

/// Первый вызов — FormatException, второй — StateError, третий — успех:
/// retry не фильтрует по типу исключения.
final class _MixedFailureGenerator implements ErrorTaskGenerator {
  _MixedFailureGenerator({required this.task});

  final ErrorHunterTask task;
  int calls = 0;

  @override
  Future<ErrorHunterTask> generateErrorTask(
    String word, {
    required String level,
  }) async {
    calls++;
    if (calls == 1) {
      throw const FormatException('malformed task');
    }
    if (calls == 2) {
      throw StateError('network');
    }
    return task;
  }
}

ErrorHunterTask task() => ErrorHunterTask(
  sentence: 'I has a book',
  wrongWord: 'has',
  correctWord: 'have',
  options: const ['have', 'has', 'had'],
);

void main() {
  test('returns the task on the first attempt', () async {
    final generator = _FlakyGenerator(failures: 0, task: task());
    final useCase = GenerateErrorTask(
      generator: generator,
      settings: FakeSettingsRepository(),
    );

    final result = await useCase('book');

    expect(result, task());
    expect(generator.calls, 1);
    expect(generator.lastWord, 'book');
    expect(generator.lastLevel, 'A1');
  });

  test('retries and succeeds on the third attempt', () async {
    final generator = _FlakyGenerator(failures: 2, task: task());
    final useCase = GenerateErrorTask(
      generator: generator,
      settings: FakeSettingsRepository(),
    );

    final result = await useCase('book');

    expect(result, task());
    expect(generator.calls, 3);
  });

  test('throws a clear error after three failed attempts', () async {
    final generator = _FlakyGenerator(failures: 3, task: task());
    final useCase = GenerateErrorTask(
      generator: generator,
      settings: FakeSettingsRepository(),
    );

    await expectLater(
      useCase('book'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Не удалось сгенерировать задание, попробуйте еще раз',
        ),
      ),
    );
    expect(generator.calls, 3);
  });

  test('retries regardless of the exception type', () async {
    final generator = _MixedFailureGenerator(task: task());
    final useCase = GenerateErrorTask(
      generator: generator,
      settings: FakeSettingsRepository(),
    );

    final result = await useCase('book');

    expect(result, task());
    expect(generator.calls, 3);
  });
}
