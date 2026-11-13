import 'package:english_edu/domain/usecases/get_cloze_task.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

import 'fakes/fake_cloze_generator.dart';
import 'fakes/fake_cloze_task_repository.dart';

final now = DateTime.utc(2024, 5, 15, 12);

final _cached = ClozeTask(
  sentence: 'She ___ tea.',
  correctWord: 'drinks',
  options: const ['drinks', 'drink', 'drank', 'drinking', 'drunk'],
);
final _generated = ClozeTask(
  sentence: 'They ___ music.',
  correctWord: 'love',
  options: const ['love', 'loves', 'loved', 'loving', 'lover'],
);

GetClozeTask useCaseOf({
  required FakeClozeTaskRepository tasks,
  required FakeClozeGenerator generator,
}) => GetClozeTask(tasks: tasks, generator: generator, clock: () => now);

void main() {
  group('GetClozeTask', () {
    test('returns cached task if exists', () async {
      final generator = FakeClozeGenerator(task: _generated);
      final useCase = useCaseOf(
        tasks: FakeClozeTaskRepository(wordId: const WordId(1), task: _cached),
        generator: generator,
      );

      final task = await useCase(const WordId(1), 'drink');

      expect(task, _cached);
      // Кэш экономит сеть: генератор не вызывается вовсе.
      expect(generator.calls, 0);
    });

    test('generates and saves if missing', () async {
      final tasks = FakeClozeTaskRepository();
      final generator = FakeClozeGenerator(task: _generated);
      final useCase = useCaseOf(tasks: tasks, generator: generator);

      final task = await useCase(const WordId(2), 'like');

      expect(task, _generated);
      expect(generator.calls, 1);
      expect(tasks.saveCalls, 1);
      expect(await tasks.getByWordId(const WordId(2)), _generated);
      // Время приходит из часов use case и уже в UTC.
      expect(tasks.lastSavedAt, now);
      expect(tasks.lastSavedAt?.isUtc, isTrue);
    });

    test('does not cache a failed generation', () async {
      final tasks = FakeClozeTaskRepository();
      final generator = FakeClozeGenerator(error: Exception('offline'));
      final useCase = useCaseOf(tasks: tasks, generator: generator);

      await expectLater(
        useCase(const WordId(3), 'eat'),
        throwsA(isA<Exception>()),
      );

      expect(tasks.saveCalls, 0);
      expect(await tasks.getByWordId(const WordId(3)), isNull);
    });
  });
}
